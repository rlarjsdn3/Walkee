//
//  ChatbotStreamingBinder.swift
//  Health
//
//  Created by Seohyun Kim on 8/28/25.
//

import UIKit

/// ChatbotViewModel 의 스트리밍 콜백을 UI(어댑터/오토스크롤/인풋바)에 연결
@MainActor
final class ChatStreamingBinder {
	private let viewModel: ChatbotViewModel
	private let adapter: ChatbotTableAdapter
	private let scroll: ChatAutoScrollManager
	private let inputBar: ChatInputBarController

	// 성능 로그
	private var e2eStart: ContinuousClock.Instant?
	private var ttfbLogged = false

	init(viewModel: ChatbotViewModel,
		 adapter: ChatbotTableAdapter,
		 scroll: ChatAutoScrollManager,
		 inputBar: ChatInputBarController) {
		self.viewModel = viewModel
		self.adapter = adapter
		self.scroll = scroll
		self.inputBar = inputBar
		bind()
	}

	private func bind() {
		viewModel.onActionText = { [weak self] text in
			guard let self else { return }
			self.adapter.updateWaitingText(text)
			self.scroll.scrollToBottomIfNeeded(force: true)
		}
		viewModel.onStreamChunk = { [weak self] chunk in
			guard let self else { return }
			if self.ttfbLogged == false, let t0 = self.e2eStart {
				let ms = t0.duration(to: .now).milliseconds
				print(String(format: "ttfb: %.3f ms", ms))
				self.ttfbLogged = true
			}
			self.adapter.beginAIStreamingIfNeeded()
			self.adapter.appendAIChunk(chunk)

			// 하단 근처일 때만 “꼬리 따라가기”
			if self.scroll.mode == .following, self.scroll.isNearBottom(threshold: 40) {
				self.scroll.scrollToBottomAbsolute(animated: false)
			}
		}
		viewModel.onStreamCompleted = { [weak self] finalText in
			guard let self else { return }
			self.adapter.finalizeAIResponse(FootnoteSanitizer.stripAllFootnotes(from: finalText))
			self.endE2E()
			self.inputBar.setEnabled(true)
			self.scroll.scrollToBottomIfNeeded(force: true)
		}
		viewModel.onError = { [weak self] err in
			guard let self else { return }
			self.adapter.finishWithErrorAutoMapped(err)
			self.endE2E()
			self.inputBar.setEnabled(true)
			self.scroll.scrollToBottomIfNeeded(force: true)
		}
	}

	func startSend(_ text: String) {
		inputBar.setEnabled(false)
		inputBar.clear()

		// 1) 사용자 버블 추가
		adapter.appendUserMessage(text)

		// 2) 로딩셀 노출
		adapter.showWaitingCell()

		// 3) 스크롤 정책
		scroll.mode = .following
		scroll.scrollToBottomIfNeeded(force: true)

		// 4) 성능 측정 시작 & 스트리밍 시작
		startE2E()
		viewModel.startPromptChatWithAutoReset(text)
	}

	private func startE2E() {
		e2eStart = .now
		ttfbLogged = false
	}
	private func endE2E() {
		guard let t0 = e2eStart else { return }
		let ms = t0.duration(to: .now).milliseconds
		print(String(format: "e2e: %.3f ms", ms))
		e2eStart = nil
	}
}
