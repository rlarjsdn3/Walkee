//
//  ChatbotViewController.swift
//  Health
//
//  Created by Seohyun Kim on 8/5/25.
//

import UIKit
import Network
import os

/// Alan ai 활용한 챗봇 화면 컨트롤러.
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
	/// 네트워크 연결 상태 - 토스트 메시지
	private var networkStatusObservationTask: Task<Void, Never>?
	private var wasPreviouslyDisconnected: Bool = false
	

	// MARK: - Lifecycle
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
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationController?.setNavigationBarHidden(true, animated: animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		navigationController?.setNavigationBarHidden(false, animated: animated)
		
		if isMovingToParent || isBeingDismissed {
			viewModel.resetSessionOnExit()
		}
	}
	
	/// 화면이 사라질 때 메모리 정리(Actor 격리 안전 영역)
	/// - Note: `deinit` 대신 여기서 Task 취소를 수행하여 Swift 6 경고를 제거
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		networkStatusObservationTask?.cancel()
		networkStatusObservationTask = nil
		scroll.stop()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		// 키보드가 없을 때만 기본 inset 복원
		scroll.adjustTableInsets()
	}
	
	override func viewSafeAreaInsetsDidChange() {
		super.viewSafeAreaInsetsDidChange()
		scroll.adjustTableInsets()
	}
	
	// MARK: - UI Setup
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
	@IBAction private func sendButtonTapped(_ sender: UIButton) {
		//sendMessageStreaming()
		guard let text = chattingTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
				  text.isEmpty == false else { return }
		binder.startSend(text)
	}
	
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
