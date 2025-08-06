import Foundation

/// DIContainer의 네트워크 서비스 등록을 위한 확장
extension DIContainer {

    /// 네트워크 서비스를 의존성 주입 컨테이너에 등록합니다.
    ///
    /// 이 메서드는 빌드 구성에 따라 적절한 네트워크 서비스 구현체를 등록합니다:
    /// - **DEBUG**: `MockNetworkService`를 등록하여 테스트 및 개발 환경에서 사용
    /// - **RELEASE**: `DefaultNetworkService`를 등록하여 프로덕션 환경에서 사용
    func registerNetworkService() {
        self.register(.networkService) { _ in
#if DEBUG
            return MockNetworkService()
#else
            return DefaultNetworkService()
#endif
        }
    }

    /// 건강 데이터 조회 서비스를 의존성 주입 컨테이너에 등록합니다.
    ///
    /// 이 메서드는 빌드 구성에 따라 적절한 HealthKit 서비스 구현체를 등록합니다:
    /// - **DEBUG**: `MockhealthService`를 등록하여 테스트 및 개발 환경에서 사용
    /// - **RELEASE**: `DefaultHealthService`를 등록하여 프로덕션 환경에서 사용
    func registerHealthService() {
        self.register(.healthService) { _ in
#if DEBUG
            return MockHealthService()
#else
            return DefaultHealthService()
#endif
        }
    }
}
