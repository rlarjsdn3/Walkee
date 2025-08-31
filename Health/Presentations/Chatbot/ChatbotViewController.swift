//
//  ChatbotViewController.swift
//  Health
//
//  Created by Seohyun Kim on 8/5/25.
//

import UIKit
import Network
import os
/// Alan AI 기반 챗봇 화면을 관리하는 뷰 컨트롤러.
///
/// `ChatbotViewController`는 Alan API SSE 스트리밍을 통해
/// 실시간으로 챗봇 응답을 받아와 UI에 표시한다.
///
/// 이 컨트롤러는 다음과 같은 역할을 수행한다:
/// - **UI 관리**: 채팅 입력창, 전송 버튼, 대화 목록(`UITableView`)의 레이아웃 및 스타일을 설정
/// - **네트워크 상태 감지**: `NetworkMonitor`를 통해 네트워크 연결 상태 변화를 감지하고, 토스트 메시지를 표시
/// - **메시지 전송**: 사용자가 입력한 텍스트를 `ChatbotViewModel`에 전달하여 SSE 스트리밍을 시작
/// - **세션 관리**: 화면이 닫히거나 이동할 때 `resetSessionOnExit()`을 호출하여 에이전트 상태를 초기화
///
/// ## 구성 요소
/// - ``ChatbotViewModel``: 챗봇 비즈니스 로직 및 SSE 관리
/// - ``ChatStreamingBinder``: ViewModel의 스트리밍 이벤트와 UI 바인딩
/// - ``ChatbotTableAdapter``: `UITableView`의 데이터 소스 및 델리게이트
/// - ``ChatAutoScrollManager``: 키보드, 안전 영역, 스크롤 동작 자동 관리
///
/// ## 주요 동작
/// - 화면 진입 시: UI 컴포넌트 초기화(`setupComponents()`), 네트워크 상태 관찰 시작
/// - 메시지 입력 후 전송: `sendButtonTapped(_:)` 또는 `ChatInputBarController.onSend` 콜백을 통해 `binder.startSend(_:)` 호출
/// - 화면 종료 시: `viewModel.resetSessionOnExit()` 실행 → 서버 세션 초기화
/// - Note: 네트워크가 끊겼다가 복구되면 토스트 메시지가 자동 표시된다.
/// - Important: 뷰가 dismiss될 때 반드시 세션 리셋이 호출되므로, 외부에서 별도 정리 코드를 호출할 필요가 없다.
@MainActor
final class ChatbotViewController: CoreGradientViewController {
	// MARK: - Outlets & Dependencies
	@Injected private var viewModel: ChatbotViewModel

	@IBOutlet weak var headerView: ChatbotHeaderTitleView!
	@IBOutlet private weak var tableView: UITableView!
	@IBOutlet private weak var containerViewBottomConstraint: NSLayoutConstraint!
	@IBOutlet private weak var chattingInputStackView: UIStackView!
	@IBOutlet private weak var chattingContainerStackView: UIStackView!
	@IBOutlet weak var chattingInputContainer: UIStackView!
	@IBOutlet private weak var chattingTextField: UITextField!
	@IBOutlet weak var disclaimerLabel: UILabel!
	@IBOutlet private weak var sendButton: UIButton!
	
	// MARK: - Components
	private var adapter: ChatbotTableAdapter!
	private var scroll: ChatAutoScrollManager!
	private var inputBar: ChatInputBarController!
	private var binder: ChatStreamingBinder!
	
	// MARK: 로그 확인용 및 마스킹 적용 PrivacyService 주입
	@Injected(.privacyService) private var privacy: PrivacyService
	
	// MARK: - Properties & States
	/// 네트워크 상태 토스트 관찰 Task.
	private var networkStatusObservationTask: Task<Void, Never>?
	/// 최근 연결 끊김 상태 플래그(복구 토스트 중복 방지).
	private var wasPreviouslyDisconnected: Bool = false
	

	// MARK: - Lifecycle
	/// 화면 초기 설정.
	/// - 구성: 속성, autolayout 제약,  헤더,  컴포넌트, 텍스트필드, 탭제스처, 네트워크 관찰 시작.
	/// - 참고: 테이블 인셋과 키보드 대응은 ``ChatAutoScrollManager`` 가 담당.
	override func viewDidLoad() {
		super.viewDidLoad()
		setupAttribute()
		setupConstraints()
		setupHeaderView()
		setupComponents()
		setUpTextFieldStyle()
		//setupTableView()
		//setupKeyboardObservers()
		setupTapGesture()
		observeNetworkStatusChanges()
	}
	/// 진입 시 네비바 숨김.
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationController?.setNavigationBarHidden(true, animated: animated)
	}
	/// 이탈 시 네비바 복원 및 세션 정리 트리거.
	/// - Note: 화면이 pop/dismiss 되는 경우에만 ``ChatbotViewModel/resetSessionOnExit()`` 호출.
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		navigationController?.setNavigationBarHidden(false, animated: animated)
		
		if isMovingToParent || isBeingDismissed {
			viewModel.resetSessionOnExit()
		}
	}
	
	/// 화면 완전 사라짐 시 리소스 정리.
	/// - 정리: 네트워크 관찰 Task 취소, 자동 스크롤 매니저 정지.
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		networkStatusObservationTask?.cancel()
		networkStatusObservationTask = nil
		scroll.stop()
	}
	/// 서브뷰 레이아웃 이후 인셋 보정.
	/// - 목적: 키보드 미표시 상태에서 테이블 기본 인셋 복원.
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		// 키보드가 없을 때만 기본 inset 복원
		scroll.adjustTableInsets()
	}
	/// `safeArea` 변경 대응 인셋 보정.
	/// - 사용 예시: 콜, 다이내믹 아일랜드, 홈 인디케이터 변화 등.
	override func viewSafeAreaInsetsDidChange() {
		super.viewSafeAreaInsetsDidChange()
		scroll.adjustTableInsets()
	}
	
	// MARK: - UI Setup
	/// 기본 스타일 적용.
	/// - 적용: 배경 그라디언트, 입력 스택 둥글림/보더.
	/// - 다크/라이트에 따른 기본 보더 컬러 지정.
	override func setupAttribute() {
		super.setupAttribute()
		
		if #available(iOS 13.0, *) { self.isModalInPresentation = true }
		
		applyBackgroundGradient(.midnightBlack)
		
		chattingInputStackView.layer.cornerRadius = 12
		chattingInputStackView.layer.masksToBounds = true
		chattingInputStackView.layer.borderWidth = BackgroundHeightUtils.calculateBorderWidth(for: traitCollection)
		chattingInputStackView.layer.borderColor = (traitCollection.userInterfaceStyle == .dark)
		? UIColor.buttonText.cgColor
		: UIColor.boxBgLightModeStroke.cgColor
	}
	/// 오토레이아웃/마진 설정.
	/// - tableView : `contentInsetAdjustmentBehavior = .never`
	/// - Chatting Container: 방향성 마진(iOS 11+) 혹은 레거시 마진 설정.
	/// - ai 안내 문구: 줄바꿈/허깅/저항 우선순위 조정.
	override func setupConstraints() {
		super.setupConstraints()
		tableView.contentInsetAdjustmentBehavior = .never
		chattingContainerStackView.isLayoutMarginsRelativeArrangement = true
		if #available(iOS 11.0, *) {
			chattingContainerStackView.directionalLayoutMargins =
			NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 12, trailing: 16)
		} else {
			chattingContainerStackView.layoutMargins =
			UIEdgeInsets(top: 8, left: 16, bottom: 12, right: 16)
		}
		disclaimerLabel?.numberOfLines = 0
		disclaimerLabel?.setContentCompressionResistancePriority(.required, for: .vertical)
		disclaimerLabel?.setContentHuggingPriority(.required, for: .vertical)
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		chattingInputStackView.layer.borderWidth = BackgroundHeightUtils.calculateBorderWidth(for: traitCollection)
		if traitCollection.userInterfaceStyle == .dark {
			chattingInputStackView.layer.borderColor = UIColor.buttonText.cgColor
			chattingInputStackView.layer.borderWidth = 1
			chattingInputStackView.layer.shadowOpacity = 0
		} else {
			chattingInputStackView.layer.borderColor = UIColor.boxBgLightModeStroke.cgColor
			BackgroundHeightUtils.setupShadow(for: chattingInputStackView)
		}
	}
	
	// MARK: - Actions
	/// 전송 버튼 탭 처리.
	/// - 검증: 공백 제거 후 비어있지 않을 때만 전송.
	/// - 동작: ``ChatStreamingBinder/startSend(_:)`` 로 위임.
	@IBAction private func sendButtonTapped(_ sender: UIButton) {
		//sendMessageStreaming()
		guard let text = chattingTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
				  text.isEmpty == false else { return }
		binder.startSend(text)
	}
	/// 네트워크 연결 상태 스트림 관찰 시작.
	/// - 연결 복구: 성공 토스트 + 상태 플래그 리셋.
	/// - 연결 끊김: 경고 토스트.
	/// - 키보드 높이에 맞춰 토스트 위치 보정.
	private func observeNetworkStatusChanges() {
		networkStatusObservationTask = Task {
			for await isConnected in await NetworkMonitor.shared.networkStatusStream() {
				await MainActor.run { [weak self] in
					guard let self = self else { return }
					let kb = self.scroll?.currentKeyboardHeight ?? 0
					
					if isConnected {
						if wasPreviouslyDisconnected {
							showToastAboveKeyboard(
								type: .success,
								title: "네트워크 연결이 복구되었습니다.",
								message: "계속해서 대화를 이어가세요 😊",
								duration: 2.5,
								keyboardHeight: kb   // scroll이 인셋 조절
							)
							wasPreviouslyDisconnected = false
						}
					} else {
						showToastAboveKeyboard(
							type: .warning,
							title: "네트워크 연결 상태를 확인해주세요.",
							message: "와이파이나 셀룰러 데이터 연결상태를 확인해주세요.",
							duration: 3.0,
							keyboardHeight: kb
						)
						wasPreviouslyDisconnected = true
					}
				}
			}
		}
	}
	
	private func setupHeaderView() {
		headerView.onCloseTapped = { [weak self] in self?.dismiss(animated: true) }
	}
	/// 화면 구성 요소 초기화.
	/// - 순서:
	///   1) AutoScroll 매니저 생성/시작 및 인셋 적용
	///   2) 테이블 어댑터 연결
	///   3) 입력 바 구성 및 `onSend` 콜백
	///   4) 스트리밍 바인더 생성 (뷰모델 ↔ UI 바인딩)
	private func setupComponents() {
		// 1) AutoScroll
		scroll = ChatAutoScrollManager(
			tableView: tableView,
			inputContainer: chattingContainerStackView,
			bottomConstraint: containerViewBottomConstraint
		)
		scroll.start()
		scroll.adjustTableInsets()
		// 2) Adapter
		adapter = ChatbotTableAdapter(tableView: tableView, scroll: scroll)
		tableView.dataSource = adapter
		tableView.delegate = adapter

		// 3) InputBar
		inputBar = ChatInputBarController(
			textField: chattingTextField,
			sendButton: sendButton,
			attachesSendTarget: false
		)
		inputBar.onSend = { [weak self] text in
			self?.binder.startSend(text)
		}
		
		binder = ChatStreamingBinder(
			viewModel: viewModel,
			adapter: adapter,
			scroll: scroll,
			inputBar: inputBar
		)
		
	}
	
	private func setUpTextFieldStyle() {
		chattingTextField.backgroundColor = .clear
		chattingTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
		chattingTextField.leftViewMode = .always
		chattingTextField.attributedPlaceholder = NSAttributedString(
			string: "워키봇에게 물어보세요.",
			attributes: [.foregroundColor: UIColor.buttonBackground.withAlphaComponent(0.5)]
		)
	}
	
	private func setupTapGesture() {
		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
	}

	@objc private func dismissKeyboard() { view.endEditing(true) }
}
