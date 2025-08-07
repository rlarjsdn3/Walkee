//
//  NetworkMonitor.swift
//  Health
//
//  Created by Seohyun Kim on 8/7/25.
//
import Network
import Foundation

/// 네트워크 연결 상태를 모니터링
///
/// `NWPathMonitor`를 사용하여 네트워크 경로 업데이트를 감지하고,
/// Swift Concurrency의 `actor`를 통해 스레드 안전하게 상태를 관리
/// `AsyncStream`을 통해 네트워크 상태 변화를 비동기적으로 제공하며,
/// `waitForConnection()` 메서드를 통해 연결이 복구될 때까지 기다림
@available(iOS 15.0, *) // iOS 15 이상에서 Swift Concurrency를 사용
actor NetworkMonitor {
	/// 싱글톤 인스턴스
	static let shared = NetworkMonitor()
	
	private let monitor = NWPathMonitor()
	private let queue = DispatchQueue(label: "NetworkMonitor.queue")
	
	/// 현재 네트워크 연결 상태
	/// 이 프로퍼티가 변경될 때마다 `networkStatusContinuation`을 통해 새로운 값을 스트림에 보냄
	private(set) var isConnected: Bool = true {
		didSet {
			// isConnected 값이 변경될 때마다 스트림에 새로운 값을 보냄
			// 액터 내부에서 상태가 변경되므로 thread safe 보장됨!
			networkStatusContinuation?.yield(isConnected)
		}
	}
	
	/// 네트워크 상태 변화를 비동기적으로 전달하기 위한 AsyncStream의 Continuation
	/// 이 Continuation을 통해 `networkStatusStream()` 구독자들에게 값을 보냄
	private var networkStatusContinuation: AsyncStream<Bool>.Continuation?
	
	/// 초기화 메서드. 네트워크 모니터링을 시작
	private init() {
		// AppDelegate에 추가
		//startMonitoring()
	}
	
	/// 네트워크 모니터링을 시작
	/// `NWPathMonitor`의 `pathUpdateHandler`를 설정하여
	/// 네트워크 경로가 변경될 때마다 `isConnected` 상태를 업데이트
	func startMonitoring() {
		monitor.pathUpdateHandler = { [weak self] path in
			Task {
				// actor의 상태를 업데이트하기 위해 Task 내부에서 await self?.updateConnectionStatus를 호출
				guard let self = self else { return }
				let newIsConnected = path.status == .satisfied
				
				// 액터의 상태를 업데이트
				// didSet이 호출되어 networkStatusContinuation에 yield
				await self.updateConnectionStatus(newIsConnected)
			}
		}
		
		// NWPathMonitor는 여전히 GCD 큐를 사용
		monitor.start(queue: queue)
	}
	
	/// 연결 상태를 업데이트
	/// 이 메서드는 액터 내부에서 호출되어 `isConnected` 상태를 안전하게 변경
	/// `isConnected`의 `didSet`이 호출되어 `networkStatusContinuation`에 값을 보냄
	private func updateConnectionStatus(_ newIsConnected: Bool) {
		if self.isConnected != newIsConnected {
			self.isConnected = newIsConnected
		}
	}
	
	/// 네트워크 연결이 복구될 때까지 대기
	///
	/// 현재 연결되어 있지 않다면, 연결이 복구될 때까지 비동기적으로 대기
	/// Swift Concurrency의 `withCheckedContinuation`을 사용하여
	/// 네트워크 상태 스트림에서 첫 번째 `true` 값을 기다림.
	func waitForConnection() async {
		if isConnected { return } // 이미 연결되어 있다면 즉시 반환
		
		// networkStatusStream()을 구독하여 연결 상태가 true가 될 때까지 대기
		// 이 스트림은 networkStatusContinuation을 통해 값을 받음
		_ = await networkStatusStream().first(where: { $0 == true })
	}
	
	/// 네트워크 상태 변화를 비동기 스트림으로 제공
	///
	/// 이 스트림을 구독하여 네트워크 연결 상태의 실시간 변화를 받을 수 있음
	/// `AsyncStream`은 여러 구독자에게 상태 변화를 알림
	func networkStatusStream() -> AsyncStream<Bool> {
		return AsyncStream { continuation in
			// 현재 연결 상태를 초기 값으로 제공합니다.
			continuation.yield(self.isConnected)
			
			// Continuation을 저장하여 나중에 네트워크 상태 변경 시 값을 yield할 수 있도록 함
			// 이 Continuation은 isConnected의 didSet에서 사용
			self.networkStatusContinuation = continuation
			
			// 스트림이 종료될 때 (예: 구독자가 더 이상 없을 때) 정리 작업을 수행
			// 이 클로저는 스트림에 대한 모든 참조가 사라지거나, 스트림이 명시적으로 `finish()`될 때 호출
			continuation.onTermination = { @Sendable [weak self] _ in
				// networkStatusContinuation을 nil로 설정하여 메모리 누수를 방지
				// 더 이상 유효하지 않은 Continuation에 접근하는 것을 방지
				Task {
					await self?.clearNetworkStatusContinuation()
					print("Network status stream terminated.")
				}
			}
		}
	}
	
	private func clearNetworkStatusContinuation() {
		self.networkStatusContinuation = nil
	}
	
	/// 모니터링을 중지
	///
	/// `NetworkMonitor` 인스턴스가 메모리에서 해제될 때 호출
	/// `NWPathMonitor`를 취소하고, `AsyncStream`의 `Continuation`을 종료해 리소스 정리
	deinit {
		monitor.cancel()
		// networkStatusContinuation이 nil이 아닐 경우 finish()를 호출하여 스트림을 명시적으로 종료
		// onTermination 클로저가 호출
		networkStatusContinuation?.finish()
		print("NetworkMonitor deinitialized and resources cleaned up.")
	}
}
