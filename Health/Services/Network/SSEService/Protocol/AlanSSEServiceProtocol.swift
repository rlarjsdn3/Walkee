//
//  AlanSSEServiceProtocol.swift
//  Health
//
//  Created by Seohyun Kim on 8/19/25.
//

import Foundation

protocol AlanSSEServiceProtocol {
	func stream(content: String) throws -> AsyncThrowingStream<AlanStreamingResponse, Error>
}
