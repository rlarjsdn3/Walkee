import Foundation

/// 네트워크 요청을 처리하는 구체적인 구현체
///
/// `URLSession`을 사용하여 실제 HTTP 요청을 수행하고,
/// 응답을 적절한 타입으로 디코딩하여 반환합니다.
///
/// ## 사용 예시
/// ```swift
/// let networkService = DefaultNetworkService()
/// let endpoint = APIEndpoint.ask(content: "안녕하세요", clientID: "client123")
/// let response = try await networkService.request(endpoint: endpoint, as: ResponseModel.self)
/// ```
final class DefaultNetworkService: NetworkService {

    /// API 요청의 기본 URL
    //private let baseURL: URL

    /// DefaultNetworkService 인스턴스를 초기화합니다
    ///
    /// - Parameter baseURL: API 서버의 기본 URL (기본값: AppConfiguration.baseURL)
    //    init(baseURL: URL = AppConfiguration.baseURL) {
    //        self.baseURL = baseURL
    //    }
    init() {

    }

    /// 지정된 엔드포인트로 네트워크 요청을 수행합니다
    ///
    /// 이 메서드는 다음과 같은 과정을 거쳐 요청을 처리합니다:
    /// 1. URL 구성 및 검증
    /// 2. HTTP 요청 설정
    /// 3. 네트워크 요청 전송
    /// 4. 응답 상태 코드 검증
    /// 5. JSON 디코딩
    ///
    /// - Parameters:
    ///   - endpoint: 요청할 API 엔드포인트
    ///   - type: 응답 데이터를 디코딩할 타입
    /// - Returns: 디코딩된 응답 데이터
    /// - Throws: 다음과 같은 `NetworkError`를 던질 수 있습니다:
    ///   - `badURL`: URL 구성 실패
    ///   - `requestFailed`: 네트워크 요청 실패
    ///   - `invalidResponse`: 유효하지 않은 HTTP 응답
    ///   - `decodingFailed`: JSON 디코딩 실패
    ///   - `validationFailed`: 서버 검증 실패 (422 상태 코드)
    func request<T: Decodable>(endpoint: APIEndpoint, as type: T.Type) async throws -> T {

        //endPoint에서 baseURL 가져오기
        let baseURL = endpoint.baseURL

        guard var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false) else {
            throw NetworkError.badURL
        }
        // 두루누비 API의 경우 특별 처리 (이중 인코딩 방지)
        if case .walkingCourses = endpoint {
            // queryItems에서 수동으로 쿼리 스트링 생성
            if let queryItems = endpoint.queryItems {
                let queryString = queryItems.compactMap { item in
                    guard let value = item.value else { return nil }

                    // serviceKey는 이미 인코딩되어 있으므로 그대로 사용
                    if item.name == "serviceKey" {
                        return "\(item.name)=\(value)"
                    } else {
                        // 다른 파라미터는 인코딩
                        let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                        return "\(item.name)=\(encodedValue)"
                    }
                }.joined(separator: "&")

                components.percentEncodedQuery = queryString
            }
        } else {
            // 다른 API는 기존 방식대로
            components.queryItems = endpoint.queryItems
        }

        guard let finalURL = components.url else {
            throw NetworkError.badURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = endpoint.method
        if let body = endpoint.body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            switch httpResponse.statusCode {
            	case 200..<300:
               	 return try JSONDecoder().decode(T.self, from: data)

           	 case 422:
               	 let validationError = try? JSONDecoder().decode(HTTPValidationError.self, from: data)
              	  let message = validationError?.detail.first?.msg ?? "Validation failed"
               	 throw NetworkError.validationFailed(message)

            default:
                throw NetworkError.invalidResponse
            }
        } catch let decodingError as DecodingError {
            throw NetworkError.decodingFailed(decodingError)
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }
}
