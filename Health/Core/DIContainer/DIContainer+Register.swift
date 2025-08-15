import Foundation

/// DIContainer의 서비스 등록을 위한 확장
///
/// 이 확장은 애플리케이션에서 사용하는 모든 서비스와 ViewModel을 의존성 주입 컨테이너에 등록하는 메서드들을 제공합니다.
/// 일부 서비스는 빌드 구성(DEBUG/RELEASE)에 따라 적절한 구현체를 선택하여 등록합니다.
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
    /// - **DEBUG**: `MockHealthService`를 등록하여 테스트 및 개발 환경에서 사용
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

    /// 사용자 정보 관리 서비스를 의존성 주입 컨테이너에 등록합니다.
    ///
    /// `DefaultCoreDataUserService`는 `CoreDataUserService` 프로토콜을 구현하며,
    /// Core Data를 통해 사용자 정보의 CRUD 작업을 처리합니다.
    /// 해당 서비스는 컨테이너에서 `.coreDataUserService` 식별자를 사용하여
    /// 타입 안전하게 해결할 수 있습니다.
    ///
    /// - Note: `CoreDataStack.shared`가 초기화되어 있어야 정상적으로 동작합니다.
    func registerCoreDataUserService() {
        self.register(.coreDataUserService) { _ in
            return DefaultCoreDataUserService()
        }
    }

    /// `DefaultPromptBuilderService`를 의존성 주입 컨테이너에 등록합니다.
    ///
    /// - Description:
    ///   - `DefaultPromptBuilderService`는 프롬프트 생성을 위한 핵심 서비스로,
    ///     사용자·건강 데이터를 수집하고 `PromptContext`를 구성하여 프롬프트를 빌드합니다.
    ///   - 해당 서비스는 `.promptGenService` 식별자를 통해 컨테이너에서 타입 안전하게 해결할 수 있습니다.
    func registerPromptBuilderService() {
        self.register(.promptBuilderService) { _ in
            return DefaultPromptBuilderService()
        }
    }

    /// `DefaultPromptRenderService`를 의존성 주입 컨테이너에 등록합니다.
    ///
    /// - Description:
    ///   - `DefaultPromptRenderService`는 지정된 `PromptContext`와 옵션을 기반으로
    ///     문자열 템플릿을 렌더링하여 완성된 프롬프트를 생성합니다.
    ///   - 해당 서비스는 `.promptTamplateRenderService` 식별자를 통해 컨테이너에서
    ///     타입 안전하게 해결할 수 있습니다.
    func registerPromptRenderService() {
        self.register(.promptRenderService) { _ in
            return DefaultPromptRenderService()
        }
    }

    /// 일일 걸음 수 관리를 담당하는 ViewModel을 의존성 주입 컨테이너에 등록합니다.
    ///
    /// `DailyStepViewModel`은 Core Data를 통해 일일 걸음 수 데이터의 CRUD 작업을 처리합니다.
    /// Core Data의 `viewContext`를 사용하여 메인 스레드에서 UI 업데이트를 보장합니다.
    ///
    /// - Parameter context: Core Data의 관리 객체 컨텍스트로 `CoreDataStack.shared.viewContext` 사용
    /// - Requires: `CoreDataStack.shared`가 초기화되어 있어야 합니다.
    func registerDailyStepViewModel() {
        self.register(.dailyStepViewModel) { _ in
            DailyStepViewModel(context: CoreDataStack.shared.viewContext)
        }
    }

    /// 목표 걸음 수 설정을 담당하는 ViewModel을 의존성 주입 컨테이너에 등록합니다.
    ///
    /// `GoalStepCountViewModel`은 사용자의 일일 목표 걸음 수를 관리하며,
    /// Core Data를 통해 목표 값의 영속성을 보장합니다.
    ///
    /// - Parameter context: Core Data의 관리 객체 컨텍스트로 `CoreDataStack.shared.viewContext` 사용
    /// - Requires: `CoreDataStack.shared`가 초기화되어 있어야 합니다.
    func registerGoalStepCountViewModel() {
        self.register(.goalStepCountViewModel) { _ in
            GoalStepCountViewModel(context: CoreDataStack.shared.viewContext)
        }
    }

    /// 걸음 수 동기화를 담당하는 ViewModel을 의존성 주입 컨테이너에 등록합니다.
    ///
    /// `StepSyncViewModel`은 HealthKit에서 걸음 수 데이터를 가져와 로컬 Core Data와 동기화하는 작업을 담당합니다.
    /// Swift Concurrency를 사용하여 비동기 동기화 작업을 수행하며, 내부적으로 `@Injected` 프로퍼티 래퍼를 사용하여
    /// 다른 서비스들에 의존합니다.
    ///
    /// - Important: 다음 의존성들이 먼저 등록되어 있어야 합니다:
    ///   - `HealthService`: HealthKit 데이터 조회를 위함
    ///   - `DailyStepViewModel`: 일일 걸음 수 데이터 관리를 위함
    ///   - `GoalStepCountViewModel`: 목표 걸음 수 관리를 위함
    func registerStepSyncViewModel() {
        self.register(.stepSyncViewModel) { _ in
            StepSyncViewModel()
        }
    }

    /// 모든 서비스와 ViewModel을 의존성 주입 컨테이너에 일괄 등록합니다.
    ///
    /// 이 메서드는 애플리케이션에서 사용하는 모든 의존성을 올바른 순서로 등록합니다.
    /// 의존성 간의 순환 참조를 방지하고 `@Injected` 프로퍼티 래퍼가 올바르게 작동하도록
    /// 등록 순서가 중요합니다.
    ///
    /// ## 등록되는 서비스 및 ViewModel (등록 순서):
    /// 1. `NetworkService` - 네트워크 통신 서비스 (독립적)
    /// 2. `HealthService` - HealthKit 데이터 조회 서비스 (독립적)
    /// 3. `DailyStepViewModel` - 일일 걸음 수 관리 (Core Data 의존)
    /// 4. `GoalStepCountViewModel` - 목표 걸음 수 관리 (Core Data 의존)
    /// 5. `StepSyncViewModel` - 걸음 수 동기화 (위 모든 서비스에 의존)
    func registerAllServices() {
        registerNetworkService()
        registerHealthService()
        registerCoreDataUserService()
        registerPromptBuilderService()
        registerPromptRenderService()
        registerDailyStepViewModel()
        registerGoalStepCountViewModel()
        registerStepSyncViewModel()
    }
}
