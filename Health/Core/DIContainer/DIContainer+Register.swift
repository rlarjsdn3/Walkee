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

    /// 달력 걸음 수 데이터 제공자를 의존성 주입 컨테이너에 등록합니다.
    ///
    /// 현재는 개발 및 테스트를 위해 `MockCalendarStepProvider`를 등록합니다.
    /// 향후 실제 Core Data 기반의 `DefaultCalendarStepProvider` 구현이 추가될 예정입니다.
    ///
    /// - Note: 달력 화면에서 일별 걸음 수 통계 데이터를 제공하는 역할을 담당합니다.
    /// - TODO: 실제 Core Data Provider 구현 추가
    func registerCalendarStepProvider() {
        self.register(.calendarStepProvider) { _ in
//#if DEBUG
            MockCalendarStepProvider()
//#else
            // TODO: 실제 CoreData Provider 추가
            // DefaultCalendarStatsProvider()
//#endif
        }
    }

    /// 달력 화면을 담당하는 ViewModel을 의존성 주입 컨테이너에 등록합니다.
    ///
    /// `CalendarViewModel`은 달력 UI의 상태 관리 및 사용자 상호작용을 처리하며,
    /// `CalendarStepProvider`에 의존하여 걸음 수 데이터를 가져옵니다.
    ///
    /// - Parameter r: DIContainer의 resolver를 통해 `CalendarStepProvider` 의존성을 주입
    /// - Important: `CalendarStepProvider`가 먼저 등록되어 있어야 합니다.
    /// - Note: Provider 해결에 실패할 경우 `MockCalendarStepProvider`를 fallback으로 사용합니다.
    func registerCalendarViewModel() {
        self.register(.calendarViewModel) { r in
            let provider: CalendarStepProvider
            if let resolved = try? r.resolve(.calendarStepProvider) {
                provider = resolved
            } else {
                provider = MockCalendarStepProvider()
            }
            return CalendarViewModel(stepProvider: provider)
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
    /// 6. `CalendarStepProvider` - 달력 걸음 수 데이터 제공자 (독립적)
    /// 7. `CalendarViewModel` - 달력 화면 관리 (`CalendarStepProvider`에 의존)
    func registerAllServices() {
        registerNetworkService()
        registerHealthService()
        registerDailyStepViewModel()
        registerGoalStepCountViewModel()
        registerStepSyncViewModel()
        registerCalendarStepProvider()
        registerCalendarViewModel()
    }
}
