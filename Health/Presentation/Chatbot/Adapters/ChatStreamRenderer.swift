//
//  ChatStreamRenderer.swift
//  Health
//
//  Created by Seohyun Kim on 8/29/25.
//

import UIKit

@MainActor
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
		cell.appendText(text)
		
		// Optional: 겹침 현상 방지 위해 레이아웃 강제
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
