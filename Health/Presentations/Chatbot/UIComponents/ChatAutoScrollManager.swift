//
//  ChatAutoScrollManager.swift
//  Health
//
//  Created by Seohyun Kim on 8/28/25.
//

import UIKit
/// 채팅 화면 전용 자동 스크롤 매니저
///
/// - 역할:
///   - 키보드 표시/숨김에 따라 안전하게 인셋 조절
///   - 사용자 스크롤 의도(`manual`) vs 자동 따라가기(`following`) 모드 전환
///   - 최신 사용자 버블/AI 응답으로 스크롤 보정
@MainActor
final class ChatAutoScrollManager {
	/// 스크롤 모드:  열거형 케이스
	enum Mode { case following, manual }
	// MARK: Properties
	private weak var tableView: UITableView?
	private weak var inputContainer: UIStackView?
	private weak var bottomConstraint: NSLayoutConstraint?

	private let keyboardObserver = KeyboardObserver()
	private(set) var currentKeyboardHeight: CGFloat = 0
	/// 현재 스크롤 모드
	var mode: Mode = .following
	/// - Parameters:
	///   - tableView: 채팅 메시지 리스트
	///   - inputContainer: 입력창 컨테이너 뷰
	///   - bottomConstraint: 입력창의 bottom constraint
	init(tableView: UITableView,
		 inputContainer: UIStackView,
		 bottomConstraint: NSLayoutConstraint) {
		self.tableView = tableView
		self.inputContainer = inputContainer
		self.bottomConstraint = bottomConstraint
	}

	// MARK: Lifecycle
	/// 키보드 관찰과 팬 제스처 감지를 시작
	func start() {
		keyboardObserver.startObserving { [weak self] payload in
			self?.applyKeyboardChange(payload)
		}
		// 사용자가 손으로 위로 스크롤하면 manual로 전환
		tableView?.panGestureRecognizer.addTarget(self, action: #selector(handlePan))
	}
	/// 관찰 중단 및 리소스 해제
	func stop() {
		keyboardObserver.stopObserving()
		tableView?.panGestureRecognizer.removeTarget(self, action: nil)
	}

	// MARK: Insets
	/// 입력창/키보드 높이에 맞춰 테이블 인셋 조정
	func adjustTableInsets() {
		guard let tv = tableView, let container = inputContainer else { return }
		let inputH = container.frame.height
		let bottomPadding: CGFloat = 32
		let bottomInset = (currentKeyboardHeight > 0)
		? (currentKeyboardHeight + inputH + bottomPadding)
		: (inputH + bottomPadding)

		tv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
		tv.scrollIndicatorInsets = tv.contentInset
	}

	// MARK: Keyboard
	private func applyKeyboardChange(_ payload: KeyboardChangePayload) {
		guard let view = tableView?.superview else { return }
		let endFrame = CGRect(x: payload.endX, y: payload.endY, width: payload.endW, height: payload.endH)
		let height = view.convert(endFrame, from: nil).intersection(view.bounds).height

		currentKeyboardHeight = height
		UIView.animate(withDuration: payload.duration,
					   delay: 0,
					   options: UIView.AnimationOptions(rawValue: payload.curveRaw << 16)) {
			self.updateBottomConstraint(forKeyboardHeight: height, in: view)
			view.layoutIfNeeded()
			self.adjustTableInsets()
		} completion: { _ in
			// 키보드가 나타나면 최신 AI 응답의 "첫 줄"로 포커스
			if height > 0 { self.scrollToLatestAIFirstLine(animated: true) }
		}
	}

	private func updateBottomConstraint(forKeyboardHeight h: CGFloat, in view: UIView) {
		let safe = view.safeAreaInsets.bottom
		bottomConstraint?.constant = (h > 0) ? -(h - safe) : 0
	}
	
	// MARK: User intent
	@objc private func handlePan(_ g: UIPanGestureRecognizer) {
		guard let tv = tableView else { return }
		if g.state == .changed || g.state == .began {
			// 위로 조금만 끌어올려도 manual로 전환
			if tv.panGestureRecognizer.translation(in: tv).y > 6 {
				mode = .manual
			}
		}
	}
	
	// MARK: Scrolling
	/// 하단 근처에 있을 때만 최신 행으로 스크롤
	/// - Parameter force: true면 무조건 바닥까지 스크롤
	func scrollToBottomIfNeeded(force: Bool = false) {
		guard let tv = tableView else { return }
		if currentKeyboardHeight > 0 { return }
		if force || isNearBottom(threshold: 120) {
			let last = max(0, tv.numberOfRows(inSection: 0) - 1)
			if last >= 0 { tv.scrollToRow(at: IndexPath(row: last, section: 0), at: .bottom, animated: true) }
		}
	}
	/// 가장 최근 AI 응답 셀의 첫 줄까지 스크롤
	func scrollToLatestAIFirstLine(animated: Bool) {
		guard let tv = tableView else { return }
		// 가장 최근 AI 셀을 찾아 상단에 보이도록 스크롤
		for row in stride(from: tv.numberOfRows(inSection: 0) - 1, through: 0, by: -1) {
			let ip = IndexPath(row: row, section: 0)
			if let cell = tv.cellForRow(at: ip) as? AIResponseCell {
				tv.layoutIfNeeded()
				tv.scrollToRow(at: ip, at: .top, animated: animated)
				return
			}
		}
	}
	
	/// 새 질문 Bubble이 화면에 들어오도록만 보정, 화면 하단으로까지는 내려가지 않는다.
	func revealLatestUserBubble(animated: Bool) {
		guard let tv = tableView else { return }
		// 마지막 행부터 위로 훑어서 '사용자 버블 셀'을 찾는다
		for row in stride(from: tv.numberOfRows(inSection: 0) - 1, through: 0, by: -1) {
			let ip = IndexPath(row: row, section: 0)

			if row >= 1 { self.scroll(to: IndexPath(row: row - 1, section: 0), position: .bottom) ; return }
		}
	}
	
	/// 사용자 버블과 AI 첫 줄이 동시에 보이도록 보정
	func revealLatestUserAndAIFirstLine(animated: Bool) {
		guard let tv = tableView else { return }
		// 가장 최근 AI 셀의 첫 줄을 top에 붙이고, 그 '바로 위' 행(대개 사용자 버블)이 함께 보이도록 middle로 보정
		for row in stride(from: tv.numberOfRows(inSection: 0) - 1, through: 0, by: -1) {
			let ip = IndexPath(row: row, section: 0)
			// 첫 줄(top) → 살짝 내려 사용자 버블이 같이 들어오게 middle 위치 조정
			self.scroll(to: ip, position: .top, duration: 0.35)
			return
		}
	}
	/// 채팅창 화면 하단의 절대 위치까지 즉시 스크롤
	func scrollToBottomAbsolute(animated: Bool) {
		guard let tv = tableView else { return }
		Task { @MainActor in
			tv.layoutIfNeeded()
			// 다음 RunLoop까지 contentSize 갱신 기다림
			await Task.yield()
			
			let insetTop = tv.adjustedContentInset.top
			let insetBottom = tv.adjustedContentInset.bottom
			let contentH = tv.contentSize.height
			let visibleH = tv.bounds.height
			let minY = -insetTop
			let maxY = max(minY, contentH - visibleH + insetBottom)
			tv.setContentOffset(CGPoint(x: 0, y: maxY), animated: animated)
		}
	}
	/// 하단 근접 여부 검사
	/// - Parameter threshold: 바닥으로부터 임계 거리(px)
	/// - Returns: true면 바닥에 근접
	func isNearBottom(threshold: CGFloat) -> Bool {
		guard let tv = tableView else { return false }
		let visibleH = tv.bounds.height - tv.adjustedContentInset.top - tv.adjustedContentInset.bottom
		let offsetY = tv.contentOffset.y
		let maxVisibleY = offsetY + visibleH
		return maxVisibleY >= (tv.contentSize.height - threshold)
	}
	/// 지정된 행으로 원하는 위치까지 애니메이션 스크롤
	/// - Parameters:
	///   - indexPath: 대상 행
	///   - position: top/middle/bottom
	///   - duration: 애니메이션 시간
	func scroll(to indexPath: IndexPath,
				position: UITableView.ScrollPosition,
				duration: TimeInterval = 0.35) {
		guard let tv = tableView else { return }
		tv.layoutIfNeeded()

		let rect = tv.rectForRow(at: indexPath)
		let targetY: CGFloat = {
			let inset = tv.adjustedContentInset
			switch position {
			case .top:
				return rect.minY - inset.top
			case .middle:
				return rect.midY - (tv.bounds.height - inset.top - inset.bottom) / 2
			default: // .bottom
				return rect.maxY - (tv.bounds.height - inset.bottom)
			}
		}()
		let minY = -tv.adjustedContentInset.top
		let maxY = max(minY, tv.contentSize.height - tv.bounds.height + tv.adjustedContentInset.bottom)
		let clamped = CGPoint(x: 0, y: max(minY, min(targetY, maxY)))

		UIView.animate(withDuration: duration, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
			tv.setContentOffset(clamped, animated: false)
		}
	}
}

extension ChatAutoScrollManager {
	/// 비동기 스크롤
	/// - Note: `duration` 만큼 `await` 후 반환
	/// 지정한 행으로 원하는 위치(`.top`, `.middle`, `.bottom`)까지 천천히 스크롤
	func scrollAsync(to indexPath: IndexPath,
					 position: UITableView.ScrollPosition,
					 duration: TimeInterval = 0.55) async {
		await withCheckedContinuation { cont in
			self.scroll(to: indexPath, position: position, duration: duration)
			DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
				cont.resume()
			}
		}
	}
}
