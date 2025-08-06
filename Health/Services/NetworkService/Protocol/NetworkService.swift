import Foundation

/// 네트워크 요청을 처리하는 서비스의 프로토콜
///
/// 네트워크 서비스의 기본 인터페이스를 정의하며, 테스트 목적으로 모킹할 수 있도록 합니다.
protocol NetworkService {

    /// 지정된 엔드포인트로 네트워크 요청을 수행합니다
    ///
    /// - Parameters:
    ///   - endpoint: 요청할 API 엔드포인트
    ///   - type: 응답 데이터를 디코딩할 타입
    /// - Returns: 디코딩된 응답 데이터
    /// - Throws: 네트워크 오류가 발생할 경우 `NetworkError`를 던집니다
    func request<T: Decodable>(endpoint: APIEndpoint, as type: T.Type) async throws -> T
}
