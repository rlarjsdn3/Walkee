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
/// let networkService = NetworkService(baseURL: AppConfiguration.baseURL)
/// ```
struct AppConfiguration {

    /// API 서버의 기본 URL
    ///
    /// - Note: 강제 언래핑(!)을 사용하므로 URL 문자열이 항상 유효해야 합니다.
    static let baseURL = URL(string: "https://kdt-api-function.azurewebsites.net")!
}
