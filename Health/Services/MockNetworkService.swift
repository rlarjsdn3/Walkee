import Foundation

/// DEBUG 환경에서 사용되는 Mock 네트워크 서비스
///
/// 실제 API를 호출하지 않고, 로컬 JSON 파일에서 데이터를 반환합니다.
final class MockNetworkService: NetworkService {

    /// Mock 응답 지연 시간 (나노초)
    private static let mockDelay: UInt64 = 500_000_000 // 0.5초

    /// 로컬 JSON 파일에서 Mock 데이터를 로드합니다
    ///
    /// - Parameters:
    ///   - endpoint: API 엔드포인트
    ///   - type: 디코딩할 타입
    /// - Returns: 디코딩된 데이터
    /// - Throws: 다음과 같은 `NetworkError`를 던집니다:
    ///   - `NetworkError.badURL`: Mock 파일을 찾을 수 없는 경우
    ///   - `NetworkError.decodingFailed(Error)`: JSON 디코딩에 실패한 경우
    ///   - `NetworkError.requestFailed(Error)`: 파일 읽기에 실패한 경우
    func request<T: Decodable>(endpoint: APIEndpoint, as type: T.Type) async throws -> T {
        // Mock 지연 시간 적용
        try await Task.sleep(nanoseconds: Self.mockDelay)

        // Mock 데이터 로드 및 디코딩
        return try await loadMockData(for: endpoint, as: type)
    }

    /// 지정된 엔드포인트에 대한 Mock 데이터를 로드합니다
    ///
    /// - Parameters:
    ///   - endpoint: API 엔드포인트
    ///   - type: 디코딩할 타입
    /// - Returns: 디코딩된 데이터
    /// - Throws: 다음과 같은 `NetworkError`를 던집니다:
    ///   - `NetworkError.badURL`: Mock 파일을 찾을 수 없는 경우
    ///   - `NetworkError.decodingFailed(DecodingError)`: JSON 디코딩에 실패한 경우
    ///   - `NetworkError.requestFailed(Error)`: 파일 읽기에 실패한 경우
    private func loadMockData<T: Decodable>(for endpoint: APIEndpoint, as type: T.Type) async throws -> T {
        let fileName = getMockFileName(for: endpoint)

        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw NetworkError.badURL
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            throw NetworkError.decodingFailed(decodingError)
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }

    /// 엔드포인트에 해당하는 Mock 파일명을 반환합니다
    ///
    /// - Parameter endpoint: API 엔드포인트
    /// - Returns: Mock JSON 파일명 (확장자 제외)
    private func getMockFileName(for endpoint: APIEndpoint) -> String {
        switch endpoint {
            case .ask:
                return "mock_ask_response"
            case .askStreaming:
                return "mock_ask_streaming_response"
            case .resetState:
                return "mock_reset_state_response"
        }
    }
}
