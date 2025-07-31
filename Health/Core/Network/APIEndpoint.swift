import Foundation

/// API 엔드포인트를 정의하는 열거형
///
/// 애플리케이션에서 사용하는 모든 API 엔드포인트를 캡슐화하고,
/// 각 엔드포인트의 경로, HTTP 메서드, 쿼리 파라미터, 요청 본문을 관리합니다.
enum APIEndpoint {

    /// 질문을 전송하는 엔드포인트
    /// - Parameters:
    ///   - content: 질문 내용
    ///   - clientID: 클라이언트 식별자
    case ask(content: String, clientID: String)

    /// 스트리밍 방식으로 질문을 전송하는 엔드포인트
    /// - Parameters:
    ///   - content: 질문 내용
    ///   - clientID: 클라이언트 식별자
    case askStreaming(content: String, clientID: String)

    /// 상태를 초기화하는 엔드포인트
    /// - Parameter clientID: 클라이언트 식별자
    case resetState(clientID: String)

    /// API 엔드포인트의 경로를 반환합니다
    ///
    /// - Returns: 각 엔드포인트에 해당하는 URL 경로 문자열
    var path: String {
        switch self {
            case .ask:
                return "/api/v1/question"
            case .askStreaming:
                return "/api/v1/question/sse-streaming"
            case .resetState:
                return "/api/v1/reset-state"
        }
    }

    /// HTTP 메서드를 반환합니다
    ///
    /// - Returns: 각 엔드포인트에 해당하는 HTTP 메서드 문자열
    var method: String {
        switch self {
            case .resetState:
                return "DELETE"
            default:
                return "GET"
        }
    }

    /// URL 쿼리 파라미터를 반환합니다
    ///
    /// - Returns: 각 엔드포인트에 필요한 쿼리 파라미터 배열, 없을 경우 nil
    var queryItems: [URLQueryItem]? {
        switch self {
            case let .ask(content, clientID),
                let .askStreaming(content, clientID):
                return [
                    URLQueryItem(name: "content", value: content),
                    URLQueryItem(name: "client_id", value: clientID)
                ]
            default:
                return nil
        }
    }

    /// HTTP 요청 본문 데이터를 반환합니다
    ///
    /// - Returns: 각 엔드포인트에 필요한 요청 본문 데이터, 없을 경우 nil
    var body: Data? {
        switch self {
            case let .resetState(clientID):
                let json: [String: String] = ["client_id": clientID]
                return try? JSONSerialization.data(withJSONObject: json)
            default:
                return nil
        }
    }
}
