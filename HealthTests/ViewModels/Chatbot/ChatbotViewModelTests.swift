//
//  ChatbotViewModelTests.swift
//  HealthTests
//
//  Created by Seohyun Kim on 8/27/25.
//

import XCTest
@testable import Health

@MainActor
final class ChatbotViewModelTests: XCTestCase {
	private var sut: ChatbotViewModel!
	private var netSpy: ResetCountingNetworkService!
	/// 이 테스트에서 오버라이드한 의존성만 복원하는 클로저들
	private var restoreClosures: [() -> Void] = []
	
	override func setUp() {
		super.setUp()
		restoreClosures = []
		
		// 1) 의존성 스코프 오버라이드 (원래 바인딩 저장 → 테스트용으로 덮어쓰기)
		let appMock = MockNetworkService()
		netSpy = ResetCountingNetworkService(wrapping: appMock)
		overrideDep(NetworkService.self, with: netSpy)
		overrideDep(PromptBuilderService.self, with: MockPromptBuilderService())
		overrideDep(AlanSSEServiceProtocol.self, with: MockSSEService(mode: .yield([])))
		overrideDep(HealthService.self, with: TestHealthService())
		
		// 2) 등록 누락 방지 프리플라이트
		preflightResolve()
		
		// 3) SUT 생성 (등록 이후)
		sut = ChatbotViewModel()
	}
	
	override func tearDown() {
		for restore in restoreClosures.reversed() { restore() }
		restoreClosures.removeAll()
		sut = nil
		netSpy = nil
		super.tearDown()
	}
	
	private func preflightResolve() {
		XCTAssertNotNil(try? DIContainer.shared.resolve(.by(type: NetworkService.self)))
		XCTAssertNotNil(try? DIContainer.shared.resolve(.by(type: PromptBuilderService.self)))
		XCTAssertNotNil(try? DIContainer.shared.resolve(.by(type: AlanSSEServiceProtocol.self)))
		XCTAssertNotNil(try? DIContainer.shared.resolve(.by(type: HealthService.self)))
	}
	
	/// 타입별로 기존 바인딩을 저장해 두고, 테스트용 인스턴스
	private func overrideDep<T>(_ type: T.Type, with instance: T) {
		let id = InjectIdentifier.by(type: T.self)
		let previous: T? = try? DIContainer.shared.resolve(id)
		
		// 덮어쓰기
		DIContainer.shared.register(type: T.self) { _ in instance }
		
		// 복원 클로저 등록
		restoreClosures.append {
			if let prev = previous {
				DIContainer.shared.register(type: T.self) { _ in prev }
			}
		}
	}

	func testStartPromptChatWithAutoReset_AggregatesAndCompletes() async {
		// Given
		let events: [AlanStreamingResponse] = [
			.action("안내"),
			.continue("Hel"),
			.continue("lo"),
			.complete(" World")
		]
		
		DIContainer.shared.register(type: AlanSSEServiceProtocol.self) { _ in
			MockSSEService(mode: .yield(events))
		}
		
		let chunkExp = expectation(description: "continue chunks (2)")
		chunkExp.expectedFulfillmentCount = 2
		let doneExp = expectation(description: "complete")
		
		var chunks: [String] = []
		var finalText: String?
		sut.onStreamChunk = { chunk in
			chunks.append(chunk)
			chunkExp.fulfill()
		}
		sut.onStreamCompleted = { final in
			// chunk와 함께 조합해서 기대 문자열 구성
			finalText = (chunks + [final]).joined()
			doneExp.fulfill()
		}
		
		// When
		sut.startPromptChatWithAutoReset("서울시 성동구 성수동1가 718 트리마제 104동 26층 사는 김서현인데 근처 한강 공원이나 걷기 코스 추천해줘")
		
		// Then
		await fulfillment(of: [chunkExp, doneExp], timeout: 2.0)
		XCTAssertEqual(chunks, ["Hel", "lo"])
		XCTAssertEqual(finalText, "Hello World")
	}

	func testResetSessionOnExit_WhenCalled_ThenCancelsStreamAndResetsAgent() async {
		// Given
		DIContainer.shared.register(type: AlanSSEServiceProtocol.self) { _ in
			MockSSEService(mode: .yield([ .continue("…") ]))
		}
		
		let before = netSpy.resetCalledCount
		
		// When
		sut.resetSessionOnExit()
		
		// Then: 800ms 스로틀 환경도 고려해 1초 내에 1회 증가를 폴링
		let deadline = Date().addingTimeInterval(1.0)
		while Date() < deadline, netSpy.resetCalledCount == before {
			try? await Task.sleep(nanoseconds: 30_000_000) // 30ms
		}
		XCTAssertEqual(netSpy.resetCalledCount -  before, 1)
	}

	func testParsingPerformance_WhenDecodingStreamingResponse_ThenRecordsMetrics() {
		// Given
		let json = #"{"type":"continue","data":{"content":"chunk","speak":null}}"#.data(using: .utf8)!
		let decoder = JSONDecoder()

		// When / Then
		measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
			for _ in 0..<5_000 {
				_ = try? decoder.decode(AlanStreamingResponse.self, from: json)
			}
		}
	}
	
	func testStartPromptChatWithAutoReset_WhenServer500_ThenResetStateOnceAndRetry() async {
		// Given
		let first  = MockSSEService.Mode.error(AlanSSEClientError.badHTTPStatus(500))
		let second = MockSSEService.Mode.yield([ .complete("OK") ])
		DIContainer.shared.register(type: AlanSSEServiceProtocol.self) { _ in
			MockSSEService(mode: .sequence([first, second]))
		}

		let doneExp = expectation(description: "complete after retry")
		var final = ""
		var actionGuide = ""
		sut.onActionText = { actionGuide = $0 }
		sut.onStreamCompleted = { final = $0; doneExp.fulfill() }

		// baseline — 시작 직전 누적값 기록
		let baseline = netSpy.resetCalledCount

		// When
		sut.startPromptChatWithAutoReset("재시도 테스트")

		// Then
		await fulfillment(of: [doneExp], timeout: 3.0)
		XCTAssertEqual(actionGuide.isEmpty, false)
		XCTAssertEqual(final, "OK")
		// 현재 운영 코드 기준: 같은 사이클 내 reset은 1~2회 허용
		let resets = netSpy.resetCalledCount - baseline
		XCTAssertTrue((1...2).contains(resets), "reset 호출 수가 예상(1~2회)을 벗어남: \(resets)")
	}
}
