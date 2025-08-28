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
	private var chunkQueue: [NSAttributedString] = []
	private var plainBuffer: String = ""
	
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
		
		responseTextView.dataDetectorTypes = []
		responseTextView.isUserInteractionEnabled = true
		responseTextView.isSelectable = true
		
		let accentColor = UIColor.accent // .accent 컬러 사용
		let linkFont = UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
		
		responseTextView.linkTextAttributes = [
			.foregroundColor: accentColor, // 링크 색상을 accentColor로 설정
			.font: linkFont, // 링크 폰트를 볼드로 설정
			.underlineStyle: NSUnderlineStyle.single.rawValue // 필요하다면 밑줄 유지 (제거하려면 .none으로 변경)
		]
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
		Task { @MainActor [weak self] in self?.onContentGrew?() }
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		// 이전 작업 마무리
		typeTask?.cancel()
		typeTask = nil
		//charQueue.removeAll(keepingCapacity: false)
		chunkQueue.removeAll()
		typewriterEnabled = false
		
		// KVO 해제
		contentSizeObs?.invalidate()
		contentSizeObs = nil
		
		//responseTextView.text = nil
		responseTextView.attributedText = nil
		plainBuffer = ""
	}
	
	private func setupWidthConstraints() {
		// 디바이스별 최대 너비 설정
		let maxTextWidth = ChatbotWidthCalculator.maxContentWidth(for: .aiResponseText)
		// Width 제약을 lessThanOrEqualTo로 설정 (고정값 아님)
		textViewWidthConstraint.constant = maxTextWidth
		// Trailing 제약 우선순위 낮게 설정
		textViewTrailingConstraint.priority = UILayoutPriority(750)
	}
	
	// MARK: - Public API (컨트롤러가 호출)
	
	/// 컨트롤러는 기존처럼 호출
	/// - during streaming: 셀 재사용 초기 바인딩 시, 비어 있으면 seed만 함(덮어씌우지 않음)
	/// - on complete: 동일 API로 호출되더라도 내부에서 "최종 렌더링"으로 교체
	func configure(with text: String) {
		configure(with: text, isFinal: true) // 완료시 경로. (cellForRow 초기 진입에도 안전함)
	}
	
	/// 필요시 명시적으로 스트리밍 중 초기 seed만 하고 싶다면 isFinal=false로도 호출 가능(컨트롤러 수정 불필요)
	func configure(with text: String, isFinal: Bool) {
		if !isFinal {
			// (스트리밍 seed 로직은 유지)
			if (responseTextView.attributedText?.length ?? 0) == 0 {
				plainBuffer = text
				let seeded = ChatMarkdownRenderer.renderChunk(text, trait: traitCollection)
				responseTextView.attributedText = seeded
				relayoutAfterUpdate()
			}
			return
		}

			// isFinal일 땐 항상 마크다운으로 재렌더 (조기리턴 금지)
			plainBuffer = text
			let rendered = ChatMarkdownRenderer.renderFinalMarkdown(text, trait: traitCollection)
			responseTextView.attributedText = rendered
			relayoutAfterUpdate()
		// 이미 같은 버퍼면 레이아웃만 틱
//		if plainBuffer == text {
//			relayoutAfterUpdate()
//			return
//		}
//		
//		// 스트리밍 중 초기 셀 바인딩(예: cellForRow에서 공백 -> 현재 누적 텍스트)
//		if !isFinal {
//			// 초기 진입에서만 seed: 이미 렌더된 내용이 있으면 건드리지 않음
//			if (responseTextView.attributedText?.length ?? 0) == 0 {
//				plainBuffer = text
//				let seeded = ChatMarkdownRenderer.renderChunk(text, trait: traitCollection)
//				responseTextView.attributedText = seeded
//				relayoutAfterUpdate()
//			} else {
//				// 이미 appendText로 실시간 갱신 중이면 무시
//			}
//			return
//		}
//		
//		// 최종 렌더링(complete 시점, 또는 표준 configure 경로)
//		plainBuffer = text
//		let rendered = ChatMarkdownRenderer.renderFinalMarkdown(text, trait: traitCollection)
//		responseTextView.attributedText = rendered
//		relayoutAfterUpdate()
	}

	// 스트리밍 "조각"이 올 때 호출 — 타자기 모드면 글자 단위로, 아니면 즉시 추가
	func appendText(_ piece: String) {
		guard piece.isEmpty == false else { return }
		plainBuffer.append(piece)
		
		let chunkAttr = ChatMarkdownRenderer.renderChunk(piece, trait: traitCollection)
		
		if typewriterEnabled {
			enqueueChunkForTypewriter(chunkAttr)
		} else {
			appendAttributedImmediately(chunkAttr)
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
			if !chunkQueue.isEmpty {
				let merged = NSMutableAttributedString()
				chunkQueue.forEach { merged.append($0) }
				chunkQueue.removeAll()
				appendAttributedImmediately(merged)
			}
		}
	}
	
	// MARK: - Markdown 처리
	// MARK: - 내부 구현
	private func appendAttributedImmediately(_ piece: NSAttributedString) {
		let current = NSMutableAttributedString(attributedString: responseTextView.attributedText ?? NSAttributedString())
		current.append(piece)
		responseTextView.attributedText = current
		relayoutAfterUpdate()
	}
	
	private func enqueueChunkForTypewriter(_ piece: NSAttributedString) {
		// 청크를 글자 단위로 나누되, 속성 유지를 위해 NSAttributedString 분해
		chunkQueue.append(piece)
		guard typeTask == nil else { return }
		
		typeTask = Task { [weak self] in
			guard let self else { return }
			while !Task.isCancelled {
				if self.chunkQueue.isEmpty {
					break
				}
				// 큐에서 하나 꺼내 문자 단위로 append
				let next = self.chunkQueue.removeFirst()
				self.typewriterAppend(next)
				try? await Task.sleep(nanoseconds: self.charDelayNanos)
			}
			await MainActor.run { self.typeTask = nil }
		}
	}
	
	@MainActor
	private func typewriterAppend(_ attr: NSAttributedString) {
		// 문자(유니코드 스칼라) 단위로 순차 추가
		attr.enumerateAttributes(in: NSRange(location: 0, length: attr.length), options: []) { attrs, range, _ in
			let substring = (attr.string as NSString).substring(with: range)
			for scalar in substring.unicodeScalars {
				let s = String(scalar)
				let ns = NSAttributedString(string: s, attributes: attrs)
				appendAttributedImmediately(ns)
			}
		}
	}
	
	private func relayoutAfterUpdate() {
		responseTextView.invalidateIntrinsicContentSize()
		responseTextView.layoutManager.allowsNonContiguousLayout = false
		responseTextView.setNeedsLayout()
		responseTextView.layoutIfNeeded()
		
		Task { @MainActor [weak self] in self?.onContentGrew?() }
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


