//
//  ChatStreamRenderer.swift
//  Health
//
//  Created by Nat Kim on 8/29/25.
//

import UIKit

final class ChatStreamRenderer {
	
	private weak var tableView: UITableView?
	private var activeCells: [IndexPath: WeakBox<AIResponseCell>] = [:]
	
	init(tableView: UITableView) {
		self.tableView = tableView
	}
	
	func registerStreamingCell(_ cell: AIResponseCell, at indexPath: IndexPath) {
		activeCells[indexPath] = WeakBox(value: cell)
	}
	
	func appendStreamingText(_ text: String, at indexPath: IndexPath) {
		guard let cell = activeCells[indexPath]?.value else { return }
		
		// 💡 안전하게 스트리밍 append
		cell.appendText(text)
		
		// 💡 레이아웃 보장 (중요)
		cell.setNeedsLayout()
		cell.layoutIfNeeded()
	}
	
	func finalizeStreamingText(_ fullText: String, at indexPath: IndexPath) {
		guard let cell = activeCells[indexPath]?.value else { return }
		cell.forceFinalize(text: fullText)
		activeCells.removeValue(forKey: indexPath)
	}
	
	func cancelStreaming(at indexPath: IndexPath) {
		activeCells[indexPath]?.value?.forceFinalize(text: "")
		activeCells.removeValue(forKey: indexPath)
	}
	
	func clearAllStreaming() {
		for (_, box) in activeCells {
			box.value?.forceFinalize(text: "")
		}
		activeCells.removeAll()
	}
}

final class WeakBox<T: AnyObject> {
	weak var value: T?
	init(value: T) {
		self.value = value
	}
}

