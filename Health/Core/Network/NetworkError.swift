import Foundation

/// 네트워크 관련 오류를 정의하는 열거형
///
/// 네트워크 요청 과정에서 발생할 수 있는 다양한 오류 상황을 캡슐화합니다.
/// 각 케이스는 특정한 오류 상황을 나타내며, 적절한 오류 처리를 위해 사용됩니다.
enum NetworkError: Error {

    /// 잘못된 URL로 인한 오류
    ///
    /// URL 구성이 실패했거나 유효하지 않은 URL일 때 발생합니다.
    case badURL

    /// 네트워크 요청 실패 오류
    ///
    /// - Parameter Error: 원본 오류 정보
    ///
    /// 네트워크 연결 문제, 타임아웃 등으로 요청이 실패했을 때 발생합니다.
    case requestFailed(Error)

    /// 유효하지 않은 응답 오류
    ///
    /// HTTP 응답이 예상과 다르거나 처리할 수 없는 형태일 때 발생합니다.
    case invalidResponse

    /// 응답 데이터 디코딩 실패 오류
    ///
    /// - Parameter Error: 디코딩 실패의 원본 오류 정보
    ///
    /// JSON 디코딩 과정에서 오류가 발생했을 때 사용됩니다.
    case decodingFailed(Error)

    /// 서버 검증 실패 오류
    ///
    /// - Parameter String: 검증 실패 메시지
    ///
    /// 서버에서 422 상태 코드와 함께 검증 오류를 반환했을 때 발생합니다.
    case validationFailed(String)

    /// 알 수 없는 오류
    ///
    /// 위의 카테고리에 속하지 않는 예상치 못한 오류 상황에 사용됩니다.
    case unknown
}
