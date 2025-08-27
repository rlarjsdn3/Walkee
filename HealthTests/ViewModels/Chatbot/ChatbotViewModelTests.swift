//
//  ChatbotViewModelTests.swift
//  HealthTests
//
//  Created by Nat Kim on 8/27/25.
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

	func testStartStreamingQuestion_WhenContinueThenComplete_ThenEmitsChunksAndFinalOnce() async {
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

		sut.onStreamChunk = { chunks.append($0); chunkExp.fulfill() }
		sut.onStreamCompleted = { finalText = $0; doneExp.fulfill() }

		// When
		sut.startStreamingQuestion("hello")

		// Then
		await fulfillment(of: [chunkExp, doneExp], timeout: 2.0)
		XCTAssertEqual(chunks, ["Hel", "lo"])
		XCTAssertEqual(finalText, " World")
	}

	func testStartStreamingQuestion_WhenServer500_ThenResetStateAndRetryOnce() async {
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

		// When
		sut.startStreamingQuestion("retry-me", autoReset: true)

		// Then
		await fulfillment(of: [doneExp], timeout: 3.0)
		XCTAssertEqual(netSpy.resetCalledCount, 1)
		XCTAssertEqual(actionGuide, "세션 초기화 후 재시도…")
		XCTAssertEqual(final, "OK")
	}

	func testStartStreamingQuestion_WhenNonRecoverableError_ThenCallsOnErrorOnly() async {
		// Given
		let nonRecoverable = NSError(domain: "Unit", code: 1234)
		DIContainer.shared.register(type: AlanSSEServiceProtocol.self) { _ in
			MockSSEService(mode: .error(nonRecoverable))
		}

		let errorExp = expectation(description: "onError called")
		var message = ""
		sut.onError = { message = $0; errorExp.fulfill() }

		// When
		sut.startStreamingQuestion("fail-now", autoReset: true)

		// Then
		await fulfillment(of: [errorExp], timeout: 2.0)
		XCTAssertTrue(message.contains("1234"))
		XCTAssertEqual(netSpy.resetCalledCount, 0)
	}

	func testResetSessionOnExit_WhenCalled_ThenCancelsStreamAndResetsAgent() async {
		// Given
		DIContainer.shared.register(type: AlanSSEServiceProtocol.self) { _ in
			MockSSEService(mode: .yield([ .continue("…") ]))
		}

		// When
		sut.resetSessionOnExit()

		// Then
		try? await Task.sleep(nanoseconds: 200_000_000)
		XCTAssertEqual(netSpy.resetCalledCount, 1)
	}

	func testStartStreamingQuestion_WhenSecondSession_ThenBufferIsCleared() async {
		// Given
		DIContainer.shared.register(type: AlanSSEServiceProtocol.self) { _ in
			MockSSEService(mode: .sequence([
				.yield([ .complete("A") ]),
				.yield([ .complete("B") ])
			]))
		}

		let first = expectation(description: "first done")
		var last = ""
		sut.onStreamCompleted = { last = $0; first.fulfill() }

		// When
		sut.startStreamingQuestion("first")
		await fulfillment(of: [first], timeout: 2.0)
		XCTAssertEqual(last, "A")

		// Then
		let second = expectation(description: "second done")
		sut.onStreamCompleted = { last = $0; second.fulfill() }
		sut.startStreamingQuestion("second")
		await fulfillment(of: [second], timeout: 2.0)
		XCTAssertEqual(last, "B")
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
}
