//
//  AIResponseCell.swift
//  Health
//
//  Created by Seohyun Kim on 8/7/25.
//

import UIKit
import os
/// 챗봇의 AI 응답을 표시하는 셀.
///
/// - 특징:
///   - 스트리밍 텍스트를 글자 단위로 표시하는 "타자기 효과" 지원
///   - `ChatMarkdownRenderer`를 사용한 마크다운 렌더링
///   - 응답 텍스트 크기에 따라 동적으로 셀 높이 조정
///
/// - 주요 메서드:
///   - ``configure(with:)``: 최종 응답 텍스트로 셀을 구성
///   - ``appendText(_:)``: SSE 조각 단위 응답을 이어붙임
///   - ``setTypewriterEnabled(_:)``: 타자기 효과 On/Off
///   - ``forceFinalize(text:)``: 스트리밍 중단 시 강제로 최종 렌더링
///
/// - Note: `onContentGrew` 클로저를 통해 높이 증가 이벤트를 상위 컨트롤러에 알림.
class AIResponseCell: CoreTableViewCell {
	@IBOutlet weak var responseTextView: UITextView!
	@IBOutlet weak var textViewWidthConstraint: NSLayoutConstraint!
	@IBOutlet weak var textViewTrailingConstraint: NSLayoutConstraint!
	
	// MARK: Typing State
	// (타자 쳐지는 듯하게 단어 혹은 글자 스트리밍 하기 위한 속성)
	private var typeTask: Task<Void, Never>?
	private var charQueue: [String] = []
	private(set) var typewriterEnabled = false
	var charDelayNanos: UInt64 = 100_000_000   // 글자당 지연 40ms 0.04
	// MARK: Height update (tableView가 begin/endupdate 할 때)
	@MainActor var onContentGrew: (() -> Void)?          // 높이 증가 알림용
	// MARK: KVO
	private var contentSizeObs: NSKeyValueObservation?
	private var chunkQueue: [NSAttributedString] = []
	private var plainBuffer: String = ""
	
	private var maxWidthConstraint: NSLayoutConstraint?
	
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
		responseTextView.textContainer.widthTracksTextView = true
		
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
		
		responseTextView.text = nil
		responseTextView.attributedText = nil
		
		// 고정 텍스트 영역 초기화
		let fixedWidth = ChatbotWidthCalculator.maxContentWidth(for: .aiResponseText)
		responseTextView.textContainer.size = CGSize(width: fixedWidth, height: .greatestFiniteMagnitude)
		responseTextView.invalidateIntrinsicContentSize()
		responseTextView.layoutManager.allowsNonContiguousLayout = false
		responseTextView.setNeedsLayout()
		responseTextView.layoutIfNeeded()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		let w = responseTextView.bounds.width
		if w > 0, responseTextView.textContainer.size.width != w {
			responseTextView.textContainer.size = CGSize(width: w, height: .greatestFiniteMagnitude)
			responseTextView.invalidateIntrinsicContentSize()
			responseTextView.setNeedsLayout()
		}
	}
	
	private func setupWidthConstraints() {
		// 1) 기존 XIB width 제약은 비활성
		textViewWidthConstraint?.isActive = false
		maxWidthConstraint?.isActive = false
		
		// 2) 기기/회전별 최대 폭 계산
		let maxTextWidth = ChatbotWidthCalculator.maxContentWidth(for: .aiResponseText)
		
		// 3) 최대폭 제약을 새로 부여 (항상 활성)
		let constraint = responseTextView.widthAnchor.constraint(lessThanOrEqualToConstant: maxTextWidth)
		constraint.priority = .required
		constraint.isActive = true
		maxWidthConstraint = constraint
		
		// 4) trailing 우선순위는 낮게 (좁아질 여지)
		textViewTrailingConstraint.priority = .defaultHigh
	}
	
	// MARK: - Public API (컨트롤러가 호출)
	/// 최종 텍스트 구성
	/// - Parameter text: 완성된 AI 응답 문자열.
	/// - Note: 내부적으로 마크다운 렌더링 적용.
	func configure(with text: String) {
		configure(with: text, isFinal: true) // 완료시 경로. (cellForRow 초기 진입에도 안전함)
	}
	
	/// 텍스트 구성 (스트리밍 seed/최종 모드)
	/// - Parameters:
	///   - text: 응답 텍스트
	///   - isFinal: 최종 여부 (false일 땐 seed만 적용)
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
	}
	
	
	/// SSE 조각 단위 텍스트 추가
	/// - Parameter piece: 이어붙일 문자열
	/// - Note: typewriter 모드 여부에 따라 처리 분기.
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
	/// 타자기 효과 활성/비활성 전환
	/// - Parameter on: 활성 여부
	/// - Note: false로 바뀔 땐 남은 큐 즉시 플러시.
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
	
	/// 스트리밍 도중 강제로 최종 렌더링 처리
	/// - Parameter text: 최종 문자열
	/// - Note: SSE가 중단되거나 에러 시 강제 마무리용.
	@MainActor
	func forceFinalize(text: String) {
		// 1) 타자 작업 종료/정리
		typeTask?.cancel()
		typeTask = nil
		chunkQueue.removeAll()
		typewriterEnabled = false
		
		// 2) 최종 마크다운 렌더
		plainBuffer = text
		let rendered = ChatMarkdownRenderer.renderFinalMarkdown(text, trait: traitCollection)
		responseTextView.attributedText = rendered
		
		// 3) 높이 재계산 트리거
		relayoutAfterUpdate()
	}
	
	private func relayoutAfterUpdate() {
		responseTextView.invalidateIntrinsicContentSize()
		responseTextView.layoutManager.allowsNonContiguousLayout = false
		responseTextView.setNeedsLayout()
		responseTextView.layoutIfNeeded()
		
		DispatchQueue.main.async { [weak self] in
			self?.onContentGrew?()
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


