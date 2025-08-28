//
//  ResetCountingNetworkService.swift
//  HealthTests
//
//  Created by Seohyun Kim on 8/27/25.
//

import Foundation
@testable import Health

/// NetworkService 호출을 감시하는 Spy.
/// - Note: .resetState 엔드포인트 호출 횟수만 카운트한다.
final class ResetCountingNetworkService: NetworkService {
	private let wrapped: NetworkService
	private(set) var resetCalledCount = 0

	init(wrapping wrapped: NetworkService) {
		self.wrapped = wrapped
	}

	/// 실제 네트워크를 위임 호출하고, .resetState면 카운트를 증가시킨다.
	/// - Parameters:
	///   - endpoint: API 엔드포인트
	///   - type: 디코딩 대상 타입
	/// - Returns: 디코딩된 응답
	func request<T: Decodable>(endpoint: APIEndpoint, as type: T.Type) async throws -> T {
		if case .resetState = endpoint { resetCalledCount += 1 }
		return try await wrapped.request(endpoint: endpoint, as: type)
	}
}

