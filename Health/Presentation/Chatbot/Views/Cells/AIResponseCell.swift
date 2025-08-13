//
//  AIResponseCell.swift
//  Health
//
//  Created by Seohyun Kim on 8/7/25.
//

import UIKit
import os

class AIResponseCell: CoreTableViewCell {
	@IBOutlet weak var responseTextView: UITextView!
	@IBOutlet weak var textViewWidthConstraint: NSLayoutConstraint!
	@IBOutlet weak var textViewTrailingConstraint: NSLayoutConstraint!
	
	// MARK: Typing State
	// (타자 쳐지는 듯하게 단어 혹은 글자 스트리밍 하기 위한 속성)
	private var typeTask: Task<Void, Never>?
	private var charQueue: [String] = []
	private(set) var typewriterEnabled = false
	var charDelayNanos: UInt64 = 40_000_000   // 글자당 지연 40ms 0.04
	var onContentGrew: (() -> Void)?          // 높이 증가 알림용
	
	
	override func setupAttribute() {
		super.setupAttribute()

		selectionStyle = .none
		responseTextView.textColor = .label
		responseTextView.textContainer.lineFragmentPadding = 0
		responseTextView.textContainerInset = .zero
		responseTextView.adjustsFontForContentSizeCategory = true
		responseTextView.isScrollEnabled = false
		
		if #available(iOS 15.0, *) {
			responseTextView.usesStandardTextScaling = true
		}
		
		setupLeftAlignment()
	}
	
	override func traitCollectionDidChange(_ previous: UITraitCollection?) {
		super.traitCollectionDidChange(previous)
		// 회전/다이내믹 타입 변경 시 최대 너비 재계산
		setupLeftAlignment()
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		// 이전 작업 마무리
		typeTask?.cancel()
		typeTask = nil
		charQueue.removeAll(keepingCapacity: false)
		
		responseTextView.text = nil
	}
	
	
	private func setupLeftAlignment() {
		// 디바이스별 최대 너비 설정
		let maxTextWidth = ChatbotWidthCalculator.maxContentWidth(for: .aiResponseText)
		textViewWidthConstraint.constant = maxTextWidth
		textViewTrailingConstraint.priority = .init(750)
	}
	
	func configure(with text: String) {
		if responseTextView.attributedText?.string == text { return }
		
		let attr = NSAttributedString(
			string: text,
			attributes: [
				.foregroundColor: responseTextView.textColor ?? .label,
				.font: responseTextView.font ?? UIFont.preferredFont(forTextStyle: .body)
			]
		)
		responseTextView.attributedText = attr
		setNeedsLayout()
		layoutIfNeeded()
	}
	
	// 스트리밍 "조각"이 올 때 호출 — 타자기 모드면 글자 단위로, 아니면 즉시 추가
	func appendText(_ piece: String) {
		guard piece.isEmpty == false else { return }
		if typewriterEnabled {
			enqueueTypewriter(piece)
		} else {
			appendImmediate(piece)
		}
	}
	
	func setTypewriterEnabled(_ on: Bool) {
		guard on != typewriterEnabled else { return }
		typewriterEnabled = on
		if on == false {
			// 1) 타자 태스크 중지
			typeTask?.cancel()
			typeTask = nil
			// 2) 남은 큐를 즉시 붙여서 절대 유실되지 않게
			if charQueue.isEmpty == false {
				appendImmediate(charQueue.joined())
				charQueue.removeAll(keepingCapacity: false)
			}
		}
	}

	
	// MARK: - 타자기 구현
	private func appendImmediate(_ piece: String) {
		let attrs: [NSAttributedString.Key: Any] = [
			.foregroundColor: responseTextView.textColor ?? .label,
			.font: responseTextView.font ?? UIFont.preferredFont(forTextStyle: .body)
		]
		let storage = responseTextView.textStorage
		storage.beginEditing()
		storage.append(NSAttributedString(string: piece, attributes: attrs))
		storage.endEditing()
		onContentGrew?()
		setNeedsLayout()
	}
	
	private func enqueueTypewriter(_ piece: String) {
		// 한국어 결합 문자도 안전하게 Character 단위로
		charQueue.append(contentsOf: piece.map { String($0) })
		guard typeTask == nil else { return }
		
		typeTask = Task { [weak self] in
			guard let self else { return }
			let attrs: [NSAttributedString.Key: Any] = [
				.foregroundColor: self.responseTextView.textColor ?? .label,
				.font: self.responseTextView.font ?? UIFont.preferredFont(forTextStyle: .body)
			]
			while Task.isCancelled == false {
				if self.charQueue.isEmpty {
					self.typeTask = nil
					break
				}
				let ch = self.charQueue.removeFirst()
				let storage = self.responseTextView.textStorage
				storage.beginEditing()
				storage.append(NSAttributedString(string: ch, attributes: attrs))
				storage.endEditing()
				
				self.onContentGrew?()
				self.responseTextView.setNeedsLayout()
				self.setNeedsLayout()
				
				try? await Task.sleep(nanoseconds: self.charDelayNanos)
			}
		}
	}
	
	private func cancelTypewriter() {
		typeTask?.cancel()
		typeTask = nil
		charQueue.removeAll(keepingCapacity: false)
	}
}
