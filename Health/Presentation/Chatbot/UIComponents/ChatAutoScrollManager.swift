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
	}
	func stop() { keyboardObserver.stopObserving() }

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
}
