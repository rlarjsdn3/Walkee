import Foundation

/// HTTP 검증 오류 응답을 나타내는 구조체
///
/// 서버에서 422 상태 코드와 함께 반환되는 검증 오류 정보를 파싱하기 위해 사용됩니다.
/// 일반적으로 요청 데이터의 형식이나 내용이 올바르지 않을 때 발생합니다.
struct HTTPValidationError: Decodable {

    /// 발생한 검증 오류들의 상세 정보 배열
    let detail: [ValidationError]
}

/// 개별 검증 오류의 상세 정보를 나타내는 구조체
///
/// 각 검증 오류에 대한 위치, 메시지, 타입 정보를 포함합니다.
struct ValidationError: Decodable {

    /// 오류가 발생한 필드의 위치 경로
    let loc: [String]

    /// 오류에 대한 설명 메시지
    let msg: String

    /// 오류의 타입
    let type: String
}
