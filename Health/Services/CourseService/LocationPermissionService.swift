//
//  LocationPermissionService.swift
//  Health
//
//  Created by juks86 on 8/14/25.
//

import CoreLocation
import UIKit

// 위치 권한을 관리하는 클래스
class LocationPermissionManager: NSObject {

    // 위치 매니저 (GPS 관련 작업을 담당)
    private let locationManager = CLLocationManager()

    // 권한 요청 완료 후 실행할 함수를 저장하는 변수
    private var permissionContinuation: CheckedContinuation<Bool, Never>?

    // 초기화 함수
    override init() {
        super.init()
        setupLocationManager()
    }

    // 위치 매니저 설정
    private func setupLocationManager() {
        locationManager.delegate = self  // 위치 관련 이벤트를 이 클래스에서 처리
    }

    // 위치 권한을 요청하는 함수
    func requestLocationPermission() async -> Bool {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            print("위치 권한 요청 중...")
            return await withCheckedContinuation { continuation in
                self.permissionContinuation = continuation
                locationManager.requestWhenInUseAuthorization()
            }

        case .denied, .restricted:
            print("위치 권한이 거부됨")
            return false

        case .authorizedWhenInUse, .authorizedAlways:
            print("위치 권한이 이미 허용됨")
            return true

        @unknown default:
            print("알 수 없는 위치 권한 상태")
            return false
        }
    }

    // 현재 위치 권한 상태를 확인하는 함수
    func checkCurrentPermissionStatus() -> Bool {
        let status = locationManager.authorizationStatus
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }
}

// MARK: - CLLocationManagerDelegate
// 위치 관련 이벤트를 처리하는 확장
extension LocationPermissionManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("위치 권한 허용됨")
            permissionContinuation?.resume(returning: true)

        case .denied, .restricted:
            print("위치 권한 거부됨")
            permissionContinuation?.resume(returning: false)

        case .notDetermined:
            print("위치 권한 아직 결정되지 않음")
            break

        @unknown default:
            print("알 수 없는 위치 권한 상태")
            permissionContinuation?.resume(returning: false)
        }

        // continuation 초기화
        permissionContinuation = nil
    }
}
