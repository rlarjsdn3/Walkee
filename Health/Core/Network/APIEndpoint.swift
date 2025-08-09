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
    
    /// 두루누비 걷기 코스 목록을 조회하는 엔드포인트
    /// - Parameters:
    ///   - crsLevel: 코스 난이도 (1: 하, 2: 중, 3: 상), nil일 경우 전체 조회
    ///   - pageNo: 페이지 번호 (기본값: 1)
    ///   - numOfRows: 한 페이지당 결과 수 (기본값: 5)
    case walkingCourses(crsLevel: String? = nil, pageNo: Int = 1, numOfRows: Int = 5)
    
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
        case .walkingCourses:
            return "/courseList"
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
            
            //두루누비 API 쿼리 파라미터
        case let .walkingCourses(crsLevel, pageNo, numOfRows):
            // 기본 허용 문자 세트에서 문제가 되는 문자들을 제거하여 새 규칙을 만듭니다.
            var allowed = CharacterSet.urlQueryAllowed
            allowed.remove(charactersIn: "+/=&") // `+`, `/`, `=`, `&`는 반드시 인코딩하도록 지정
            
            // 이 새 규칙으로 서비스 키를 직접 인코딩합니다.
            let encodedServiceKey = AppConfiguration.tourAPIServiceKey.addingPercentEncoding(withAllowedCharacters: allowed)
            
            // 인코딩된 키(encodedServiceKey)를 사용하여 URLQueryItem을 만듭니다.
            var items = [
                URLQueryItem(name: "serviceKey", value: encodedServiceKey),
                URLQueryItem(name: "pageNo", value: "\(pageNo)"),
                URLQueryItem(name: "numOfRows", value: "\(numOfRows)"),
                URLQueryItem(name: "MobileOS", value: "IOS"),
                URLQueryItem(name: "MobileApp", value: "HealthWalkingApp"),
                URLQueryItem(name: "_type", value: "json")
            ]
            
            if let crsLevel = crsLevel {
                items.append(URLQueryItem(name: "crsLevel", value: crsLevel))
            }
            
            return items
            
        default:
            return nil
        }
    }
    
    /// HTTP 요청 본문 데이터를 반환합니다
    ///
    /// - Returns: 각 엔드포인트에 필요한 요청 본문 데이터, 없을 경우 nil
    //  엔드포인트별 베이스 URL 구분
    var baseURL: URL {
        switch self {
        case  .walkingCourses:
            return AppConfiguration.tourAPIBaseURL
        default:
            return AppConfiguration.baseURL // 기존 메인 API URL
        }
    }
    
    var body: Data? {
        switch self {
        default:
            return nil  // 현재는 모든 엔드포인트가 GET/DELETE
        }
    }
}
