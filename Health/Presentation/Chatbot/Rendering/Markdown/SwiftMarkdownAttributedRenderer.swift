//
//  SwiftMarkdownAttributedRenderer.swift
//  Health
//
//  Created by Seohyun Kim on 8/22/25.
//
import UIKit
import Markdown

// MARK: - Swift-Markdown -> NSAttributedString
///SwiftMarkdownAttributedRenderer는 Swift-Markdown 라이브러리의 Document를 받아서 NSAttributedString으로 렌더링하는 클래스
final class SwiftMarkdownAttributedRenderer {
	private let trait: UITraitCollection?
	private let isChunk: Bool
	let baseFont: UIFont
	
	init(trait: UITraitCollection? = nil, isChunk: Bool = false) {
		self.trait = trait
		self.isChunk = isChunk
		if let trait = trait {
			self.baseFont = UIFont.preferredFont(forTextStyle: .body, compatibleWith: trait)
		} else {
			self.baseFont = UIFont.preferredFont(forTextStyle: .body)
		}
	}

	func render(document: Document) -> NSAttributedString {
		let out = NSMutableAttributedString()
		//render(blocks: document.children, into: out)
		print("📦 [디버깅] Document 파싱 결과 블록들:")
		for (i, block) in document.children.enumerated() {
			print(
				"  [\(i)] 타입: \(type(of: block)) - 내용: \(String(describing: block.debugDescription))"
			)
		}
		
		render(blocks: document.children, into: out)
		
		print("🧾 최종 렌더링 결과 문자열:\n\(out.string)")
		
		return out
	}

	private func bodyFont() -> UIFont { UIFont.preferredFont(forTextStyle: .body) }
	private func monoFont() -> UIFont { UIFont.monospacedSystemFont(ofSize: bodyFont().pointSize, weight: .regular) }

	private func para(_ spacing: CGFloat = 6) -> NSParagraphStyle {
		let p = NSMutableParagraphStyle()
		p.lineSpacing = 2
		p.paragraphSpacing = spacing
		p.lineBreakMode = .byWordWrapping
		return p
	}
	
	private func maybeAppendNewline(_ out: NSMutableAttributedString) { if !isChunk { out.append(NSAttributedString(string: "\n")) } }

	// MarkupChildren를 직접 받도록 수정
	private func render(blocks: MarkupChildren, into out: NSMutableAttributedString) {
			for block in blocks {
				switch block {
				case let p as Paragraph:
					let s = renderInline(p.inlineChildren)
					// 문단 전체에 .font를 주지 않습니다 (인라인 굵기/기울임 보호)
					s.addAttributes([
						.foregroundColor: UIColor.label,
						.paragraphStyle: para()
					], range: NSRange(location: 0, length: s.length))
					out.append(s)
					maybeAppendNewline(out)

				case let h as Heading:
					let s = renderInline(h.inlineChildren)
					let idx = max(1, min(h.level, 6)) - 1
					let weight: UIFont.Weight = [.bold, .semibold, .medium, .regular, .regular, .regular][idx]
					let f = UIFont.systemFont(ofSize: bodyFont().pointSize + CGFloat(max(0, 6 - h.level)), weight: weight)
					s.addAttributes([
						.font: f,
						.foregroundColor: UIColor.label,
						.paragraphStyle: para(8)
					], range: NSRange(location: 0, length: s.length))
					out.append(s)
					maybeAppendNewline(out)

				case let list as OrderedList:
					var idx = 1
					for item in list.listItems {
						out.append(NSAttributedString(string: "\(idx). ", attributes: [
							.font: bodyFont(),
							.foregroundColor: UIColor.label
						]))
						render(blocks: item.children, into: out)
						maybeAppendNewline(out)
						idx += 1
					}

				case let list as UnorderedList:
					for item in list.listItems {
						out.append(NSAttributedString(string: "• ", attributes: [
							.font: bodyFont(),
							.foregroundColor: UIColor.label
						]))
						render(blocks: item.children, into: out)
						maybeAppendNewline(out)
					}

				case let code as CodeBlock:
					out.append(NSAttributedString(string: code.code, attributes: [
						.font: monoFont(),
						.foregroundColor: UIColor.label,
						.backgroundColor: UIColor.secondarySystemFill,
						.paragraphStyle: para(8)
					]))
					maybeAppendNewline(out)

				case let bq as BlockQuote:
					let quoted = NSMutableAttributedString()
					render(blocks: bq.children, into: quoted)
					let line = NSMutableAttributedString(string: "▎ ")
					line.addAttributes([.foregroundColor: UIColor.systemTeal], range: NSRange(location: 0, length: 1))
					line.append(quoted)
					out.append(line)
					maybeAppendNewline(out)

				default:
					out.append(NSAttributedString(string: block.format()))
					maybeAppendNewline(out)
				}
			}
		}

	// any InlineMarkup 시퀀스를 제네릭으로 받음
	private func renderInline<S: Sequence>(_ inlines: S) -> NSMutableAttributedString where S.Element == any InlineMarkup {
		let out = NSMutableAttributedString()
		let inlineArray = Array(inlines)
		for (index, inline) in inlineArray.enumerated() {
			switch inline {
			case let strong as Strong:
				let inner = renderInline(strong.inlineChildren)
				let styled = NSMutableAttributedString(attributedString: inner)
				styled.addAttributes([
					.font: UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
				], range: NSRange(location: 0, length: styled.length))
				out.append(styled)
			case let e as Emphasis:
				let inner = renderInline(e.inlineChildren)
				let attrs: [NSAttributedString.Key: Any] = [
					.font: UIFont.italicSystemFont(ofSize: bodyFont().pointSize)
				]
				inner.addAttributes(attrs, range: NSRange(location: 0, length: inner.length))
				out.append(inner)

			case let code as InlineCode:
				let attrs: [NSAttributedString.Key: Any] = [
					.font: monoFont(),
					.backgroundColor: UIColor.secondarySystemFill
				]
				out.append(NSAttributedString(string: code.code, attributes: attrs))

			case let link as Link:
				if let dest = link.destination, let url = URL(string: dest) {
					out.append(createAttributedLinkString(link: link, url: url))
					if index < inlineArray.count - 1 {
						out.append(NSAttributedString(string: "\n"))
					}
				} else {
					// 🔧 마크다운 문법이 유지되도록 Text 대신 마크다운 렌더 블럭을 통째로 돌림
					let fallbackText = link.plainText
					let fallbackDoc = Document(parsing: fallbackText)
					let fallbackAttr = render(document: fallbackDoc)
					out.append(fallbackAttr)
				}
			case _ as LineBreak:
				out.append(NSAttributedString(string: "\n"))
			case let t as Text:
//				let clean = t.string.trimmingCharacters(in: CharacterSet(charactersIn: "()."))
				out.append(NSAttributedString(string: t.string, attributes: [
					.font: bodyFont()
				]))
			default:
				out.append(NSAttributedString(string: inline.plainText))
			}
		}
		return out
	}

	// MARK: - Helper Method for Link Rendering
	/// 링크 요소를 NSAttributedString으로 변환하고 SF Symbols 및 텍스트를 추가합니다.
	private func createAttributedLinkString(link: Link, url: URL) -> NSAttributedString {
		let combinedLinkString = NSMutableAttributedString()
		// 스타일 정의
		let linkDisplayColor = UIColor.accent
		let linkDisplayFont = UIFont.boldSystemFont(ofSize: bodyFont().pointSize)
		let symbolFontSize = bodyFont().pointSize + 1.5
		// SF Symbols 아이콘 설정
		if let image = UIImage(systemName: "link.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: symbolFontSize, weight: .bold)) {
			let attachment = NSTextAttachment(image: image)
			let symbolString = NSMutableAttributedString(attachment: attachment)
			symbolString.addAttributes([.foregroundColor: linkDisplayColor], range: NSRange(location: 0, length: symbolString.length))
			
			combinedLinkString.append(NSAttributedString(string: "[", attributes: [.font: linkDisplayFont, .foregroundColor: linkDisplayColor]))
			combinedLinkString.append(symbolString)
			combinedLinkString.append(NSAttributedString(string: " 링크", attributes: [.font: linkDisplayFont, .foregroundColor: linkDisplayColor]))
			combinedLinkString.append(NSAttributedString(string: "] : ", attributes: [.font: linkDisplayFont, .foregroundColor: linkDisplayColor]))
		} else {
			let fallbackString = NSAttributedString(string: "[링크] : ", attributes: [
				.font: linkDisplayFont,
				.foregroundColor: linkDisplayColor
			])
			combinedLinkString.append(fallbackString)
		}
		// 원본 텍스트 렌더링 및 조건별 처리
		let originalInner = renderInline(link.inlineChildren)
		let originalString = originalInner.string
		let finalInner: NSMutableAttributedString
		
		if originalString.contains("출처") {
			// 출처 텍스트일 경우만 괄호 + 마침표 제거
			let cleanedString = originalString
				.replacingOccurrences(of: "(", with: "")
				.replacingOccurrences(of: ")", with: "")
				.replacingOccurrences(of: ".", with: "")
			finalInner = NSMutableAttributedString(string: cleanedString, attributes: originalInner.attributes(at: 0, effectiveRange: nil))
		} else {
			// 일반 문장은 그대로 사용
			finalInner = NSMutableAttributedString(attributedString: originalInner)
		}
		// 링크 속성 적용
		finalInner.addAttributes([
			.link: url,
			.font: linkDisplayFont,
			.foregroundColor: linkDisplayColor,
			.underlineStyle: NSUnderlineStyle.single.rawValue
		], range: NSRange(location: 0, length: finalInner.length))
		combinedLinkString.append(finalInner)
		// 앞부분 다시 스타일 부여
		combinedLinkString.addAttributes([
			.foregroundColor: linkDisplayColor,
			.font: linkDisplayFont
		], range: NSRange(location: 0, length: combinedLinkString.length))

		return combinedLinkString
	}
}
