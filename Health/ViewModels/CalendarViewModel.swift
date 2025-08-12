import Foundation

/// 달력의 월 데이터를 나타내는 구조체
struct CalendarMonthData {
    let year: Int
    let month: Int
}

/// 달력 데이터 변경 유형을 정의하는 열거형
enum CalendarDataChanges {
    case topInsert([IndexPath]) // 상단에 새 아이템 삽입
    case bottomInsert([IndexPath]) // 하단에 새 아이템 삽입
    case reload // 전체 데이터 새로고침
}

/// 달력 화면의 비즈니스 로직을 담당하는 뷰모델
@MainActor
final class CalendarViewModel: ObservableObject {

    /// 달력에 표시할 월 데이터 배열 (현재 로드된 모든 월)
    @Published private(set) var months: [CalendarMonthData] = []

    /// 데이터 변경 이벤트를 방출하는 AsyncStream
    private let dataChangesSubject = AsyncStream<CalendarDataChanges>.makeStream()

    /// 데이터 변경 이벤트를 구독할 수 있는 AsyncStream
    var dataChanges: AsyncStream<CalendarDataChanges> {
        dataChangesSubject.stream
    }

    /// 상단 로딩중 여부를 나타내는 플래그 (중복 요청 방지)
    private var isLoadingTop = false

    /// 하단 로딩중 여부를 나타내는 플래그 (중복 요청 방지)
    private var isLoadingBottom = false

    /// 월 데이터 생성을 담당하는 헬퍼 객체
    private let monthsGenerator = CalendarMonthsGenerator()

    /// 현재 로드된 월의 총 개수를 반환
    var monthsCount: Int {
        months.count
    }

    init() {
        setupInitialMonths()
    }

    /// 지정된 인덱스의 월 데이터를 안전하게 반환
    /// - Parameter index: 배열 인덱스 (0부터 시작)
    /// - Returns: 해당 인덱스의 월 데이터. 인덱스가 유효하지 않으면 `nil` 반환
    func month(at index: Int) -> CalendarMonthData? {
        guard (0..<months.count).contains(index) else { return nil }
        return months[index]
    }

    /// 현재 월의 IndexPath를 찾아서 반환
    /// - Returns: 현재 월에 해당하는 IndexPath, 없으면 nil
    func indexOfCurrentMonth() -> IndexPath? {
        let today = Date()
        guard let index = months.firstIndex(where: {
            $0.year == today.year && $0.month == today.month
        }) else {
            return nil
        }
        return IndexPath(item: index, section: 0)
    }

    /// 상단에 과거 년도의 월 데이터를 추가로 로드 (무한 스크롤)
    /// - Note: 비동기로 실행되며, 중복 호출 방지 로직 포함
    func loadMoreTop() async {
        guard !isLoadingTop else { return }
        isLoadingTop = true
        defer { isLoadingTop = false }

        guard let firstMonth = months.first else { return }

        let newMonths = monthsGenerator.generateMonths(
            fromYear: firstMonth.year - 2,
            toYear: firstMonth.year - 1
        )

        guard !newMonths.isEmpty else { return }

        months.insert(contentsOf: newMonths, at: 0)

        let indexPaths = (0..<newMonths.count).map {
            IndexPath(item: $0, section: 0)
        }

        dataChangesSubject.continuation.yield(.topInsert(indexPaths))
    }

    /// 하단에 미래 년도의 월 데이터를 추가로 로드 (무한 스크롤)
    /// - Note: 비동기로 실행되며, 중복 호출 방지 로직 포함
    func loadMoreBottom() async {
        guard !isLoadingBottom else { return }
        isLoadingBottom = true
        defer { isLoadingBottom = false }

        guard let lastMonth = months.last else { return }

        let newMonths = monthsGenerator.generateMonths(
            fromYear: lastMonth.year + 1,
            toYear: lastMonth.year + 2
        )

        guard !newMonths.isEmpty else { return }


        let startIndex = months.count
        months.append(contentsOf: newMonths)

        let indexPaths = (startIndex..<months.count).map {
            IndexPath(item: $0, section: 0)
        }

        dataChangesSubject.continuation.yield(.bottomInsert(indexPaths))
    }
}

private extension CalendarViewModel {

    /// 앱 시작 시 초기 월 데이터 설정 (현재 연도 기준 ±2년)
    /// - Note: 총 5년치 60개월 데이터를 생성
    func setupInitialMonths() {
        let currentYear = Date().year
        months = monthsGenerator.generateMonths(
            fromYear: currentYear - 2,
            toYear: currentYear + 2
        )
    }
}

/// 달력 월 데이터 생성을 담당하는 헬퍼 클래스
final class CalendarMonthsGenerator {

    /// 지정된 연도 범위의 모든 월 데이터를 생성
    /// - Parameters:
    ///   - startYear: 시작 연도 (포함)
    ///   - endYear: 종료 연도 (포함)
    /// - Returns: 생성된 월 데이터 배열 (연도순, 월순으로 정렬)
    func generateMonths(fromYear startYear: Int, toYear endYear: Int) -> [CalendarMonthData] {
        var result: [CalendarMonthData] = []

        for year in startYear...endYear {
            for month in 1...12 {
                result.append(CalendarMonthData(year: year, month: month))
            }
        }

        return result
    }
}
