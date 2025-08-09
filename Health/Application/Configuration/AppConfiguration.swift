//
//  AppConfiguration.swift
//  Health
//
//  Created by 김건우 on 7/28/25.
//

import Foundation

/// 애플리케이션 전역 설정을 관리하는 구조체
///
/// 앱에서 사용되는 공통 설정값들을 중앙에서 관리합니다.
/// 환경별 설정이나 전역적으로 사용되는 상수값들을 포함합니다.
///
/// ## 주요 용도
/// - API 서버 기본 URL 설정
/// - 환경별 설정 분리
/// - 애플리케이션 공통 상수 관리
///
/// ## 사용 예시
/// ```swift
/// let networkService = DefaultNetworkService(baseURL: AppConfiguration.baseURL)
/// ```
struct AppConfiguration {

    /// API 서버의 기본 URL
    ///
    /// - Note: 강제 언래핑(!)을 사용하므로 URL 문자열이 항상 유효해야 합니다.
    static let baseURL = URL(string: "https://kdt-api-function.azurewebsites.net")!

    // 두루누비 API 설정 추가
    ///한국관광공사 두루누비 API URL
    static let tourAPIBaseURL = URL(string: "http://apis.data.go.kr/B551011/Durunubi")!
    
    //두루누비 API서비스 키
    static let tourAPIServiceKey = "+WDbwCcbExGwifwnw3UtciWJVsS4Bgf/bCLk5AE3jakkte4V5OaX7GSU+tkj5ScHHjF6sfb8MiYvAQ5nMsGM6Q=="

    /// 현재 앱의 클라이언트 식별자
    ///
    /// Info.plist의 `CURRENT_CLIENT_ID` 키에서 클라이언트 ID를 가져옵니다.
    /// 이 값은 API 호출 시 클라이언트를 식별하거나 환경별 설정을 구분하는 데 사용됩니다.
    ///
    /// - Returns: Info.plist에 설정된 클라이언트 ID 문자열. 값이 없으면 "unknown"을 반환합니다.
    ///
    /// - **Important**: Info.plist에 `CURRENT_CLIENT_ID` 키가 올바르게 설정되어 있는지 확인하세요.
    static var clientID: String {
        Bundle.main.object(forInfoDictionaryKey: "Client ID") as? String ?? "unknown"
    }
}
