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

	override func setUp() {
		super.setUp()
		DIContainer.shared.removeAllDependencies()
		registerChatbotDeps()
		sut = ChatbotViewModel()
	}

	override func tearDown() {
		sut = nil
		netSpy = nil
		DIContainer.shared.removeAllDependencies()
		super.tearDown()
	}
	
	private func registerChatbotDeps() {
		// NetworkService: 앱의 MockNetworkService(로컬 JSON 로더)를 감싼 Spy
		let appMock = MockNetworkService()
		netSpy = ResetCountingNetworkService(wrapping: appMock)
		DIContainer.shared.register(type: NetworkService.self) { _ in self.netSpy }
		
		// PromptBuilderService (프로토콜 시그니처 일치하는 목)
		DIContainer.shared.register(type: PromptBuilderService.self) { _ in MockPromptBuilderService() }
		
		DIContainer.shared.register(type: HealthService.self) { _ in TestHealthService() }
		
		// AlanSSEServiceProtocol (기본은 빈 스트림; 각 테스트에서 재등록해 시나리오 주입)
		DIContainer.shared.register(type: AlanSSEServiceProtocol.self) { _ in MockSSEService(mode: .yield([])) }
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
