import Foundation

/// 네트워크 관련 오류를 정의하는 열거형
///
/// 네트워크 요청 과정에서 발생할 수 있는 다양한 오류 상황을 캡슐화합니다.
/// 각 케이스는 특정한 오류 상황을 나타내며, 적절한 오류 처리를 위해 사용됩니다.
enum NetworkError: Error {
	//  MARK: - API 관련 에러
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

	// MARK: - 인터넷 네트워크 연결 관련 에러
	/// 인터넷 연결이 없는 경우
	case notConnectedToInternet
	
	/// 요청 타임아웃
	case timedOut
	/// 알 수 없는 오류
	///
	/// 위의 카테고리에 속하지 않는 예상치 못한 오류 상황에 사용됩니다.
	case unknown
	
	/// viewModel 등에서 String으로 전달되는 일반 오류 메시지를 위한 케이스 추가
	case customMessage(String)
}

extension NetworkError {
	var errorDetailMsgs: String {
		switch self {
		case .badURL:
			return "잘못된 주소입니다."
		case .requestFailed:
			return "ALAN AI API 서버 네트워크 관련 오류입니다."
		case .notConnectedToInternet:
			return "인터넷에 연결되어 있지 않습니다. 연결을 확인해주세요."
		case .timedOut:
			return "요청 시간이 초과되었습니다. 잠시 후 다시 시도해주세요."
		case .invalidResponse:
			return "API 서버 응답에 문제가 있습니다."
		case .decodingFailed(_):
			return "API 응답 데이터 처리 중 문제가 발생했습니다."
		case .validationFailed(let message):
			return "입력 내용을 확인해주세요: \(message)"
		case .unknown:
			return "일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
		/// 새로운 케이스에 대한 메시지 반환
		case .customMessage(let message):
			return message
		}
	}
}
