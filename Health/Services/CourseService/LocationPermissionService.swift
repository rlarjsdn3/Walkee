//
//  LocationPermissionService.swift
//  Health
//
//  Created by juks86 on 8/14/25.
//

import CoreLocation
import UIKit

// 위치 권한을 관리하는 클래스
@MainActor
class LocationPermissionService: NSObject {

    @MainActor static let shared = LocationPermissionService()

    // 위치 매니저 (GPS 관련 작업을 담당)
    private let locationManager = CLLocationManager()

    // 권한 요청 완료 후 실행할 함수를 저장하는 변수
    private var permissionContinuation: CheckedContinuation<Bool, Never>?

    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    private var cachedLocation: CLLocation?
    private var lastLocationTime: Date?
    private let locationCacheValidDuration: TimeInterval = 600 // 10분 캐시

    // 초기화 함수
    override init() {
        super.init()
        setupLocationManager()
    }

    // 위치 매니저 설정
    private func setupLocationManager() {
        locationManager.delegate = self  // 위치 관련 이벤트를 이 클래스에서 처리

        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 500
    }

    //캐시된 위치가 유효한지 확인
    private func getCachedLocationIfAvailable() -> CLLocation? {
        guard let cachedLocation = cachedLocation,
              let lastTime = lastLocationTime,
              Date().timeIntervalSince(lastTime) < locationCacheValidDuration else {
            return nil
        }
        return cachedLocation
    }

    // 내 현재 위치 가져오기 (메인 함수)
    func getCurrentLocation() async -> CLLocation? {
        guard checkCurrentPermissionStatus() else {
            print("위치 권한이 없습니다.")
            return nil
        }

        // 캐시된 위치가 있으면 바로 반환 (빠름!)
        if let cachedLocation = getCachedLocationIfAvailable() {
            print("캐시된 위치 사용: \(cachedLocation.coordinate)")
            return cachedLocation
        }

        // 이미 요청 중이면 이전 위치라도 반환
        if locationContinuation != nil {
            print("이미 위치 요청 중 - 캐시된 위치 반환")
            return cachedLocation
        }

        print("새로운 위치 요청")
        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()
        }
    }

    //즉시 사용 가능한 위치 반환
    func getLocationImmediately() -> CLLocation? {
        return getCachedLocationIfAvailable()
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

    func isPermissionNotDetermined() -> Bool {
        return locationManager.authorizationStatus == .notDetermined
    }
}

// MARK: - CLLocationManagerDelegate
// 위치 관련 이벤트를 처리하는 확장

extension LocationPermissionService: CLLocationManagerDelegate {

    // 위치 업데이트 처리
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 모든 작업을 Task 블록 안으로 이동
        Task { @MainActor in
            guard let location = locations.last else { return }

            // ✅ '보안 구역' 안에서 안전하게 물건을 만지는 중
            self.cachedLocation = location
            self.lastLocationTime = Date()
            self.locationContinuation?.resume(returning: location)
            self.locationContinuation = nil
        }
    }

    //위치요청실패 처리
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("위치 요청 실패: \(error.localizedDescription)")

            // 대기 중인 continuation에 nil 전달
            self.locationContinuation?.resume(returning: nil)
            self.locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                print("위치 권한 허용됨")
                self.permissionContinuation?.resume(returning: true)

            case .denied, .restricted:
                print("위치 권한 거부됨")
                self.permissionContinuation?.resume(returning: false)

            case .notDetermined:
                print("위치 권한 아직 결정되지 않음")
                break

            @unknown default:
                print("알 수 없는 위치 권한 상태")
                self.permissionContinuation?.resume(returning: false)
            }

            // continuation 초기화
            self.permissionContinuation = nil
        }
    }
}
