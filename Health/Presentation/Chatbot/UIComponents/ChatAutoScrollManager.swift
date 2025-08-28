//
//  ChatAutoScrollManager.swift
//  Health
//
//  Created by Seohyun Kim on 8/28/25.
//

import UIKit

@MainActor
final class ChatAutoScrollManager {
	enum Mode { case following, manual }

	private weak var tableView: UITableView?
	private weak var inputContainer: UIStackView?
	private weak var bottomConstraint: NSLayoutConstraint?

	private let keyboardObserver = KeyboardObserver()
	private(set) var currentKeyboardHeight: CGFloat = 0

	var mode: Mode = .following
	
	init(tableView: UITableView,
		 inputContainer: UIStackView,
		 bottomConstraint: NSLayoutConstraint) {
		self.tableView = tableView
		self.inputContainer = inputContainer
		self.bottomConstraint = bottomConstraint
	}

	// MARK: Lifecycle
	func start() {
		keyboardObserver.startObserving { [weak self] payload in
			self?.applyKeyboardChange(payload)
		}
		// 사용자가 손으로 위로 스크롤하면 manual로 전환
		tableView?.panGestureRecognizer.addTarget(self, action: #selector(handlePan))
	}
	func stop() {
		keyboardObserver.stopObserving()
		tableView?.panGestureRecognizer.removeTarget(self, action: nil)
	}

	// MARK: Insets
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
	func scrollToBottomIfNeeded(force: Bool = false) {
		guard let tv = tableView else { return }
		if currentKeyboardHeight > 0 { return }
		if force || isNearBottom(threshold: 120) {
			let last = max(0, tv.numberOfRows(inSection: 0) - 1)
			if last >= 0 { tv.scrollToRow(at: IndexPath(row: last, section: 0), at: .bottom, animated: true) }
		}
	}

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
	
	/// 새 질문 Bubble이 화면에 들어오도록만 보정 (바닥으로 몰지 않음)
	func revealLatestUserBubble(animated: Bool) {
		guard let tv = tableView else { return }
		// 마지막 행부터 위로 훑어서 '사용자 버블 셀'을 찾는다
		for row in stride(from: tv.numberOfRows(inSection: 0) - 1, through: 0, by: -1) {
			let ip = IndexPath(row: row, section: 0)
			// 오프스크린이어도 rectForRow는 동작하므로, 셀 타입을 직접 확인하지 말고
			// '버블 셀 식별자'를 Adapter가 tag/접두어로 설정했다면 row 구간 규칙을 사용하거나
			// 최근 사용자 메시지 인덱스를 Adapter에서 제공받는 편이 더 안전함.
			// 여기서는 '마지막에서 두 번째가 사용자 버블' 패턴(뒤에 waiting/AI가 붙는 구조)을 기본값으로 사용
			if row >= 1 { self.scroll(to: IndexPath(row: row - 1, section: 0), position: .bottom) ; return }
		}
	}
	
	/// “질문 Bubble + AI 첫 줄”이 동시에 보이도록 살짝만 보정
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

	func scrollToBottomAbsolute(animated: Bool) {
		guard let tv = tableView else { return }
		tv.layoutIfNeeded()
		let insetTop = tv.adjustedContentInset.top
		let insetBottom = tv.adjustedContentInset.bottom
		let contentH = tv.contentSize.height
		let visibleH = tv.bounds.height
		let minY = -insetTop
		let maxY = max(minY, contentH - visibleH + insetBottom)
		tv.setContentOffset(CGPoint(x: 0, y: maxY), animated: animated)
	}

	func isNearBottom(threshold: CGFloat) -> Bool {
		guard let tv = tableView else { return false }
		let visibleH = tv.bounds.height - tv.adjustedContentInset.top - tv.adjustedContentInset.bottom
		let offsetY = tv.contentOffset.y
		let maxVisibleY = offsetY + visibleH
		return maxVisibleY >= (tv.contentSize.height - threshold)
	}
	
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
	/// 지정한 행으로 원하는 위치(.top/.middle/.bottom)까지 천천히 스크롤
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
