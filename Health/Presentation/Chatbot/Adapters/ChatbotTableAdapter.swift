//
//  ChatbotTableAdapter.swift
//  Health
//
//  Created by Seohyun Kim on 8/28/25.
//

import UIKit

@MainActor
final class ChatbotTableAdapter: NSObject {
	// MARK: - State
	private(set) var messages: [ChatMessage] = []
	private(set) var waitingState: WaitingCellState? = nil
	private(set) var streamingAIIndex: Int?

	private weak var tableView: UITableView?
	
	private var lastRelayoutTS: CFAbsoluteTime = 0
	private let relayoutMinInterval: CFTimeInterval = 0.05
	
	// 스트리밍 타자 옵션
	var streamingTypewriterEnabled: Bool = true
	var streamingCharDelayNanos: UInt64 = 80_000_000
	
	init(tableView: UITableView) {
		self.tableView = tableView
		super.init()
		setupTableView()
	}

	private func setupTableView() {
		tableView?.backgroundColor = .clear
		tableView?.separatorStyle = .none
		tableView?.keyboardDismissMode = .interactive
		if #available(iOS 17.0, *) {
			tableView?.selfSizingInvalidation = .enabledIncludingConstraints
		}
		tableView?.showsVerticalScrollIndicator = false
		tableView?.contentInsetAdjustmentBehavior = .never
		tableView?.estimatedRowHeight = 80
		tableView?.rowHeight = UITableView.automaticDimension

		tableView?.register(BubbleViewCell.nib, forCellReuseIdentifier: BubbleViewCell.id)
		tableView?.register(AIResponseCell.nib, forCellReuseIdentifier: AIResponseCell.id)
		tableView?.register(LoadingResponseCell.self, forCellReuseIdentifier: LoadingResponseCell.id)
	}

	// MARK: - Public API
	func appendUserMessage(_ text: String) {
		messages.append(ChatMessage(text: text, type: .user))
		insertRows([IndexPath(row: messages.count - 1, section: 0)])
	}
	
	func showWaitingCell(initialText: String? = nil) {
		let fallback = "응답을 생성 중입니다. 조금만 더 기다려주세요.."
		let text = (initialText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
		? initialText! : fallback
		waitingState = .waiting(text)
		insertRows([IndexPath(row: messages.count, section: 0)])
	}

	func updateWaitingText(_ text: String) {
		guard let tv = tableView, case .waiting = waitingState else { return }
		waitingState = .waiting(text)
		let ip = IndexPath(row: messages.count, section: 0)
		if let cell = tv.cellForRow(at: ip) as? LoadingResponseCell {
			cell.configure(text: text, animating: true)
		}
	}

	func beginAIStreamingIfNeeded() {
		guard streamingAIIndex == nil, let tv = tableView else { return }

		let insertRow = messages.count
		messages.append(ChatMessage(text: "", type: .ai))
		streamingAIIndex = insertRow

		tv.performBatchUpdates({
			if waitingState != nil {
				let waitIP = IndexPath(row: insertRow, section: 0)
				tv.deleteRows(at: [waitIP], with: .fade)
				waitingState = nil
			}
			tv.insertRows(at: [IndexPath(row: insertRow, section: 0)], with: .fade)
		})

		if let cell = tv.cellForRow(at: IndexPath(row: insertRow, section: 0)) as? AIResponseCell {
			cell.configure(with: "", isFinal: false)
		}
	}

	func appendAIChunk(_ chunk: String) {
		guard let idx = streamingAIIndex else { return }
		messages[idx].text.append(chunk)
		let ip = IndexPath(row: idx, section: 0)

		if let cell = tableView?.cellForRow(at: ip) as? AIResponseCell {
			cell.appendText(chunk)
		} else {
			UIView.performWithoutAnimation {
				tableView?.reloadRows(at: [ip], with: .none)
			}
		}
	}
	
	//최신 User/AI 인덱스 조회(오프스크린이어도 안전)
	func indexPathForLatestUser() -> IndexPath? {
		guard let i = messages.lastIndex(where: { $0.type == .user }) else { return nil }
		return IndexPath(row: i, section: 0)
	}
	
	func indexPathForLatestAI() -> IndexPath? {
		guard let i = messages.lastIndex(where: { $0.type == .ai }) else { return nil }
		return IndexPath(row: i, section: 0)
	}

	func finalizeAIResponse(_ finalText: String) {
		guard let idx = streamingAIIndex else { return }
		messages[idx].text = finalText
		let ip = IndexPath(row: idx, section: 0)

		if let cell = tableView?.cellForRow(at: ip) as? AIResponseCell {
			//cell.configure(with: finalText, isFinal: true)
			cell.forceFinalize(text: finalText)
		} else {
			UIView.performWithoutAnimation {
				tableView?.reloadRows(at: [ip], with: .none)
			}
		}
		streamingAIIndex = nil
	}

	func finishWithError(_ message: String) {
		waitingState = .error(message)
		let ip = IndexPath(row: messages.count, section: 0)
		if let cell = tableView?.cellForRow(at: ip) as? LoadingResponseCell {
			cell.configure(text: message, animating: false)
		}
	}

	func numberOfRows() -> Int {
		messages.count + (waitingState != nil ? 1 : 0)
	}

	private func insertRows(_ ips: [IndexPath]) {
		tableView?.performBatchUpdates {
			tableView?.insertRows(at: ips, with: .none)
		}
	}
}

// MARK: - UITableViewDataSource / Delegate
extension ChatbotTableAdapter: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		numberOfRows()
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		// 대기 셀
		if let state = waitingState, indexPath.row == messages.count {
			let cell = tableView.dequeueReusableCell(
				withIdentifier: LoadingResponseCell.id,
				for: indexPath
			) as! LoadingResponseCell

			switch state {
			case .waiting(let txt):
				let fallback = "응답을 생성 중입니다. 조금만 더 기다려주세요.."
				let t = txt.isEmpty ? fallback : txt
				cell.configure(text: t, animating: true)
			case .error(let msg):
				cell.configure(text: msg, animating: false)
			}
			return cell
		}

		let msg = messages[indexPath.row]
		switch msg.type {
		case .user:
			let cell = tableView.dequeueReusableCell(
				withIdentifier: BubbleViewCell.id,
				for: indexPath
			) as! BubbleViewCell
			cell.configure(with: msg.text)
			return cell

		case .ai:
			let cell = tableView.dequeueReusableCell(
				withIdentifier: AIResponseCell.id, for: indexPath
			) as! AIResponseCell
			let isStreaming = (streamingAIIndex == indexPath.row)
			cell.configure(with: msg.text, isFinal: !isStreaming)
			// 스트리밍 중이면 타자 모드 적용(느리게)
			if isStreaming {
				cell.setTypewriterEnabled(streamingTypewriterEnabled)
				cell.charDelayNanos = streamingCharDelayNanos
			}
			
			// Old VC와 동일한 높이 갱신 루프 연결
			cell.onContentGrew = { [weak self] in
				guard let self = self else { return }
				let now = CFAbsoluteTimeGetCurrent()
				guard now - self.lastRelayoutTS >= self.relayoutMinInterval else { return }
				self.lastRelayoutTS = now
				
				UIView.performWithoutAnimation {
					tableView.beginUpdates()
					tableView.endUpdates()
				}
			}
			return cell

		case .loading:
			// 필요하다면 MessageType.loading을 일반 메시지로도 표시 가능
			let cell = tableView.dequeueReusableCell(
				withIdentifier: LoadingResponseCell.id,
				for: indexPath
			) as! LoadingResponseCell
			cell.configure(text: msg.text, animating: true)
			return cell
		}
	}
}

@MainActor
extension ChatbotTableAdapter {
	
	func showWaitingCellWithDefault() {
		
		showWaitingCell(initialText: "응답을 생성 중입니다. 조금만 더 기다려주세요..")
	}
	func finishWithErrorAutoMapped(_ raw: String) {
		if raw.contains("401") || raw.localizedCaseInsensitiveContains("unauthorized") {
			finishWithError("인증이 만료되었습니다. 다시 시도해 주세요. (401)")
		} else {
			finishWithError("AI에서 응답 받는 것을 실패했습니다. 24시간 후에 다시 시도해주세요.")
		}
	}
}
