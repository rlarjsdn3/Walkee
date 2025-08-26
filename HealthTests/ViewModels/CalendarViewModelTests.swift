import XCTest
@testable import Health

@MainActor
final class CalendarViewModelTests: XCTestCase {

    private var sut: CalendarViewModel!

    override func setUp() {
        super.setUp()
        sut = CalendarViewModel()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testInit_WhenCreated_ThenContainsFiveYearsOfMonths() {
        // given
        let expectedYears = 5 // 현재 연도 ±2년
        let monthsPerYear = 12

        // then
        XCTAssertEqual(sut.monthsCount, expectedYears * monthsPerYear)
    }

    func testMonthAt_WhenIndexIsInvalid_ThenReturnNil() {
        // then
        XCTAssertNil(sut.month(at: -1))
        XCTAssertNil(sut.month(at: sut.monthsCount))
    }

    func testMonthAt_WhenIndexIsValid_ThenReturnMonthData() {
        // when
        let month = sut.month(at: 0)

        // then
        XCTAssertNotNil(month)
        XCTAssertTrue((1...12).contains(month?.month ?? 0))
        XCTAssertNotNil(month?.year)
    }

    func testIndexOfCurrentMonth_WhenCalled_ThenReturnValidIndexPath() {
        // when
        let indexPath = sut.indexOfCurrentMonth()

        // then
        XCTAssertNotNil(indexPath)
        XCTAssertTrue((0..<sut.monthsCount).contains(indexPath?.item ?? -1))
    }

    func testLoadMoreTop_WhenCalled_ThenInsertsMonthsAtBeginning() async {
        // given
        let initialCount = sut.monthsCount

        // when
        await sut.loadMoreTop()

        // then
        XCTAssertTrue(sut.monthsCount > initialCount)
        XCTAssertEqual(sut.month(at: 0)?.month, 1) // 항상 1월부터 시작
    }

    func testLoadMoreBottom_WhenCalled_ThenAppendsMonthsAtEnd() async {
        // given
        let initialCount = sut.monthsCount

        // when
        await sut.loadMoreBottom()

        // then
        XCTAssertTrue(sut.monthsCount > initialCount)
    }
}
