//
//  ChatbotTableAdapter.swift
//  Health
//
//  Created by Seohyun Kim on 8/28/25.
//

import UIKit
/// UITableView 데이터소스/델리게이트 어댑터
/// - User/AI/로딩 메시지를 행 단위로 관리
/// - 스트리밍 중인 셀 갱신 및 자동 스크롤 처리
@MainActor
final class ChatbotTableAdapter: NSObject {
	// MARK: - State, Properties
	private(set) var messages: [ChatMessage] = []
	private(set) var waitingState: WaitingCellState? = nil
	private(set) var streamingAIIndex: Int?

	private weak var tableView: UITableView?
	
	private var lastRelayoutTS: CFAbsoluteTime = 0
	private let relayoutMinInterval: CFTimeInterval = 0.05
	
	// 스트리밍 옵션(속도 등)
	var streamingTypewriterEnabled: Bool = true
	var streamingCharDelayNanos: UInt64 = 80_000_000
	
	private let scroll: ChatAutoScrollManager
	private let renderer: ChatStreamRenderer
	
	/// TableView와 Scroll 관리자 주입
	init(
		tableView: UITableView,
		scroll: ChatAutoScrollManager
	) {
		self.tableView = tableView
		self.scroll = scroll
		self.renderer = ChatStreamRenderer(tableView: tableView)
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
	/// 사용자 메시지 추가
	func appendUserMessage(_ text: String) {
		messages.append(ChatMessage(text: text, type: .user))
		insertRows([IndexPath(row: messages.count - 1, section: 0)])
	}
	/// 로딩 셀 표시
	func showWaitingCell(initialText: String? = nil) {
		let fallback = "응답을 생성 중입니다. 조금만 더 기다려주세요.."
		let text = (initialText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
		? initialText! : fallback
		
		if let state = waitingState {
			waitingState = .waiting(text)
			let ip = IndexPath(row: messages.count, section: 0)
			if let tv = tableView {
				if let cell = tv.cellForRow(at: ip) as? LoadingResponseCell {
					cell.configure(text: text, animating: true)
				} else {
					UIView.performWithoutAnimation {
						tv.reloadRows(at: [ip], with: .none)
					}
				}
			}
			return
		}
		
		waitingState = .waiting(text)
		insertRows([IndexPath(row: messages.count, section: 0)])
	}
	/// 로딩 셀 텍스트 갱신
	func updateWaitingText(_ text: String) {
		guard let tv = tableView, case .waiting = waitingState else { return }
		waitingState = .waiting(text)
		let ip = IndexPath(row: messages.count, section: 0)
		if let cell = tv.cellForRow(at: ip) as? LoadingResponseCell {
			cell.configure(text: text, animating: true)
		}
	}
	/// AI 스트리밍 시작 시 셀 삽입
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
	/// AI 청크 추가
	func appendAIChunk(_ chunk: String) {
		guard let idx = streamingAIIndex else { return }
		messages[idx].text.append(chunk)
		let ip = IndexPath(row: idx, section: 0)
		
		if tableView?.cellForRow(at: ip) is AIResponseCell {
			renderer.appendStreamingText(chunk, at: ip)
		} else {
			// 화면에 없으면 데이터만 누적하고 필요 시 한 번에 갱신
			UIView.performWithoutAnimation {
				tableView?.reloadRows(at: [ip], with: .none)
			}
		}
	}
	
	//최신 User, AI 인덱스 조회
	func indexPathForLatestUser() -> IndexPath? {
		guard let i = messages.lastIndex(where: { $0.type == .user }) else { return nil }
		return IndexPath(row: i, section: 0)
	}
	
	func indexPathForLatestAI() -> IndexPath? {
		guard let i = messages.lastIndex(where: { $0.type == .ai }) else { return nil }
		return IndexPath(row: i, section: 0)
	}
	/// 최종 응답 완료 처리
	func finalizeAIResponse(_ finalText: String) {
		guard let idx = streamingAIIndex else { return }
		messages[idx].text = finalText
		let ip = IndexPath(row: idx, section: 0)

		if tableView?.cellForRow(at: ip) is AIResponseCell {
				renderer.finalizeStreamingText(finalText, at: ip)
			} else {
				UIView.performWithoutAnimation {
					tableView?.reloadRows(at: [ip], with: .none)
				}
			}
		
		streamingAIIndex = nil
	}
	/// 에러 셀 표시
	func finishWithError(_ message: String) {
		waitingState = .error(message)
		let ip = IndexPath(row: messages.count, section: 0)
		if let cell = tableView?.cellForRow(at: ip) as? LoadingResponseCell {
			cell.configure(text: message, animating: false)
		}
	}
	/// 총 행 개수
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
			
			// 동일한 높이 갱신 루프 연결
			cell.onContentGrew = { [weak self] in
				guard let self = self else { return }
				let now = CFAbsoluteTimeGetCurrent()
				guard now - self.lastRelayoutTS >= self.relayoutMinInterval else { return }
				self.lastRelayoutTS = now
				
				UIView.performWithoutAnimation {
					tableView.beginUpdates()
					tableView.endUpdates()
				}
				
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) {
					Task {
						await MainActor.run {
							if self.scroll.mode == .following {
								self.scroll.scrollToBottomAbsolute(animated: false)
							}
						}
					}
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
	
	func tableView(_ tableView: UITableView,
				   willDisplay cell: UITableViewCell,
				   forRowAt indexPath: IndexPath) {
		// 현재 스트리밍 중인 행만 렌더러에 등록
		if let ai = cell as? AIResponseCell, streamingAIIndex == indexPath.row {
			renderer.registerStreamingCell(ai, at: indexPath)
		}
	}

	func tableView(_ tableView: UITableView,
				   didEndDisplaying cell: UITableViewCell,
				   forRowAt indexPath: IndexPath) {
		// 화면에서 사라지는 순간 스트리밍 연결 해제 (교차오염 방지)
		renderer.cancelStreaming(at: indexPath)
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
