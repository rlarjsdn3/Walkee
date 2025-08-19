//
//  AlanSSEClientProtocol.swift
//  Health
//
//  Created by Seohyun Kim on 8/19/25.
//

import Foundation

protocol AlanSSEClientProtocol {
	func connect(url: URL) -> AsyncThrowingStream<AlanStreamingResponse, Error>
	func disconnect()
}
