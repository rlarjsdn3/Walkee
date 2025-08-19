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
	// MARK: Height update (tableView가 begin/endupdate 할 때)
	@MainActor var onContentGrew: (() -> Void)?          // 높이 증가 알림용
	// MARK: KVO
	private var contentSizeObs: NSKeyValueObservation?
	
	override func setupAttribute() {
		super.setupAttribute()
		
		responseTextView.textColor = .label
		responseTextView.backgroundColor = .clear
		responseTextView.isEditable = false
		responseTextView.isScrollEnabled = false
		responseTextView.showsVerticalScrollIndicator = false
		responseTextView.showsHorizontalScrollIndicator = false
		
		// TextContainer 설정 - 텍스트 잘림 방지
		responseTextView.textContainer.lineFragmentPadding = 0
		responseTextView.textContainerInset = .zero
		responseTextView.textContainer.lineBreakMode = .byWordWrapping
		responseTextView.textContainer.maximumNumberOfLines = 0
		
		// 폰트 및 접근성
		responseTextView.adjustsFontForContentSizeCategory = true
		if #available(iOS 15.0, *) { responseTextView.usesStandardTextScaling = true }
		
		// 우선순위 설정 - 높이는 늘어나고, 너비는 제한
		responseTextView.setContentCompressionResistancePriority(.required, for: .vertical)
		responseTextView.setContentHuggingPriority(.defaultLow, for: .vertical)
		responseTextView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
		responseTextView.setContentHuggingPriority(.defaultLow, for: .horizontal)
	}
	
	override func setupConstraints() {
		// contentSize 변경될 때마다 테이블 높이 다시 계산됨
		contentSizeObs?.invalidate()
		contentSizeObs = responseTextView.observe(\.contentSize, options: [.new]) { [weak self] _, _ in
			// KVO 콜백은 @Sendable 문맥이므로 메인 액터로 hop
			Task { @MainActor [weak self] in
				self?.onContentGrew?()
			}
		}
		
		setupWidthConstraints()
	}
	
	override func traitCollectionDidChange(_ previous: UITraitCollection?) {
		super.traitCollectionDidChange(previous)
		// 회전/다이내믹 타입 변경 시 최대 너비 재계산
		setupWidthConstraints()
		Task { @MainActor [weak self] in
			self?.onContentGrew?()
		}
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		// 이전 작업 마무리
		typeTask?.cancel()
		typeTask = nil
		charQueue.removeAll(keepingCapacity: false)
		typewriterEnabled = false
		
		// KVO 해제
		contentSizeObs?.invalidate()
		contentSizeObs = nil
		
		responseTextView.text = nil
	}
	
	private func setupWidthConstraints() {
		// 디바이스별 최대 너비 설정
		let maxTextWidth = ChatbotWidthCalculator.maxContentWidth(for: .aiResponseText)
		
		// Width 제약을 lessThanOrEqualTo로 설정 (고정값 아님)
		textViewWidthConstraint.constant = maxTextWidth
		
		// Trailing 제약 우선순위 낮게 설정
		textViewTrailingConstraint.priority = UILayoutPriority(750)
	}

	func configure(with text: String) {
		if responseTextView.text == text {
			responseTextView.invalidateIntrinsicContentSize()
			setNeedsLayout()
			onContentGrew?()          // 테이블 begin/endUpdates 트리거
			return
		}
		
		responseTextView.text = text
		
		responseTextView.invalidateIntrinsicContentSize()
		setNeedsLayout()
		// 다음 런루프에 contentSize가 업데이트된 뒤 테이블 갱신
		Task { @MainActor [weak self] in
			self?.onContentGrew?()
		}
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
				let remaining = charQueue.joined()
				charQueue.removeAll(keepingCapacity: false)
				appendImmediate(remaining)
			}
		}
	}

	// MARK: - 타자기 구현
	private func appendImmediate(_ piece: String) {
		let currentText = responseTextView.text ?? ""
		responseTextView.text = currentText + piece
		
		// 레이아웃 선계산 (붙자마자)
		responseTextView.invalidateIntrinsicContentSize()
		responseTextView.layoutManager.allowsNonContiguousLayout = false
		responseTextView.setNeedsLayout()
		// 1) 즉시 레이아웃 한 번
		responseTextView.layoutIfNeeded()
		
		// 2) 다음 런루프에서(= contentSize 반영된 뒤) 테이블에게 높이 재계산 요청
		Task { @MainActor [weak self] in
			self?.onContentGrew?()
		}
	}

	private func enqueueTypewriter(_ piece: String) {
		// 문자 단위로 큐에 추가
		charQueue.append(contentsOf: piece.map { String($0) })
		
		// 이미 타이핑 중이면 리턴
		guard typeTask == nil else { return }
		
		typeTask = Task { [weak self] in
			guard let self else { return }
			
			while !Task.isCancelled && !self.charQueue.isEmpty {
				let char = self.charQueue.removeFirst()
				
				// 메인 스레드에서 UI 업데이트
				await MainActor.run {
					let currentText = self.responseTextView.text ?? ""
					self.responseTextView.text = currentText + char
					self.responseTextView.invalidateIntrinsicContentSize()
					self.onContentGrew?()
					self.setNeedsLayout()
				}
				// 지연
				try? await Task.sleep(nanoseconds: self.charDelayNanos)
			}
			
			// 태스크 완료
			await MainActor.run {
				self.typeTask = nil
			}
		}
	}
	
	private func cancelTypewriter() {
		typeTask?.cancel()
		typeTask = nil
		charQueue.removeAll(keepingCapacity: false)
	}
}


