//
//  ChatMarkdownRenderer.swift
//  Health
//
//  Created by Seohyun Kim on 8/21/25.
//

import UIKit
import Markdown

enum ChatMarkdownRenderer {
	// 공통 스타일(문단 & 색상). 여기서 .font는 넣으면 안됨 — 인라인 굵게/기울임을 살려야 함.
	private static func baseParagraphStyle() -> NSParagraphStyle {
		let p = NSMutableParagraphStyle()
		p.lineBreakMode = .byWordWrapping
		p.lineSpacing = 2
		p.paragraphSpacing = 6
		return p
	}
	
	// MARK: - 최종 렌더(complete) — Markdown 100% 적용
	static func renderFinalMarkdown(_ fullText: String, trait: UITraitCollection? = nil) -> NSAttributedString {
		let normalized = normalizeNewlines(fullText)
		print("📨 [MarkdownRenderer] 최종 렌더링 전 normalized 텍스트:\n\(normalized)")
		let document = Document(parsing: normalized)
		
		// 2) SwiftMarkdownAttributedRenderer를 사용하여 NSAttributedString으로 렌더링
		let renderer = SwiftMarkdownAttributedRenderer(trait: trait, isChunk: false)
		let attributedString = NSMutableAttributedString(attributedString: renderer.render(document: document))

		return attributedString

	}
	
	// MARK: - 스트리밍 청크 렌더 — 마크다운 파싱하지 않음(성능 + 깜빡임 방지)
	static func renderChunk(_ chunk: String, trait: UITraitCollection? = nil) -> NSAttributedString {
		// \r\n, \r → \n만 정규화. 추가 개행/리스트 가공 X
		let unified = chunk
			.replacingOccurrences(of: "\r\n", with: "\n")
			.replacingOccurrences(of: "\r", with: "\n")
		
		let paragraph = NSMutableParagraphStyle()
		paragraph.lineBreakMode = .byWordWrapping
		paragraph.lineSpacing = 2
		// 청크는 문단 간격 추가하지 않음
		paragraph.paragraphSpacing = 0
		
		let attrs: [NSAttributedString.Key: Any] = [
			.font: UIFont.preferredFont(forTextStyle: .body),
			.foregroundColor: UIColor.label,
			.paragraphStyle: paragraph
		]
		let ns = NSMutableAttributedString(string: unified, attributes: attrs)
		return LinkDetector.highlightLinks(in: ns)
	}
	
	// MARK: - 개행 정규화 유틸
	private static func normalizeNewlines(_ s: String) -> String {
		let unified = s.replacingOccurrences(of: "\r\n", with: "\n")
			.replacingOccurrences(of: "\r", with: "\n")
		// 3개 이상 연속 개행 → 2개로 축약
		return unified.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
	}
}

