//
//  NetworkMonitor.swift
//  Health
//
//  Created by Nat Kim on 8/7/25.
//
import Network
import Foundation

class NetworkMonitor {
	static let shared = NetworkMonitor()
	
	private let monitor = NWPathMonitor()
	private var monitoringTask: Task<Void, Never>?
	
	// 현재 연결 상태
	private var _isConnected = true
	private let statusQueue = DispatchQueue(label: "NetworkMonitor.status", attributes: .concurrent)
	
	var isConnected: Bool {
		return statusQueue.sync { _isConnected }
	}
	
	// UIKit용 클로저 콜백 - @Sendable로 타입 안전성 확보
	var networkStatusChanged: (@Sendable (Bool) -> Void)?
	
	private init() {
		startMonitoring()
	}
	
	private func startMonitoring() {
		monitor.pathUpdateHandler = { [weak self] path in
			let isConnected = path.status == .satisfied
			
			self?.statusQueue.async(flags: .barrier) { [weak self] in
				guard let self = self else { return }
				
				if self._isConnected != isConnected {
					self._isConnected = isConnected
					
					// 메인 스레드에서 콜백 호출
					DispatchQueue.main.async {
						self.networkStatusChanged?(isConnected)
					}
				}
			}
		}
		
		monitor.start(queue: DispatchQueue(label: "NetworkMonitor.queue"))
	}
	
	// AsyncStream 방식으로 네트워크 상태 스트림 제공
	func networkStatusStream() -> AsyncStream<Bool> {
		AsyncStream { continuation in
			// 현재 상태 먼저 전달
			continuation.yield(isConnected)
			
			// 기존 콜백 백업
			let originalCallback = networkStatusChanged
			
			// 새로운 콜백 설정
			networkStatusChanged = { @Sendable isConnected in
				originalCallback?(isConnected)
				continuation.yield(isConnected)
			}
			
			continuation.onTermination = { [weak self] _ in
				// 스트림 종료 시 원래 콜백 복원
				Task { @MainActor in
					self?.networkStatusChanged = originalCallback
				}
			}
		}
	}
	
	deinit {
		monitoringTask?.cancel()
		monitor.cancel()
	}
}

// MARK: - 편의 메서드들
extension NetworkMonitor {
	
	/// 현재 네트워크 연결 상태를 확인
	func checkNetworkStatus() async -> Bool {
		return isConnected
	}
	
	/// 네트워크 연결 대기
	func waitForConnection() async {
		if isConnected { return }
		
		await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
			let originalCallback = networkStatusChanged
			
			networkStatusChanged = { @Sendable [weak self] isConnected in
				originalCallback?(isConnected)
				
				if isConnected {
					Task { @MainActor in
						self?.networkStatusChanged = originalCallback
					}
					continuation.resume()
				}
			}
		}
	}
}
