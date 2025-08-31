//
//  LocationPermissionService.swift
//  Health
//
//  Created by juks86 on 8/14/25.
//

import CoreLocation
import UIKit

/// 위치 권한을 관리하고 현재 위치를 가져오는 서비스 클래스
///
/// 이 클래스는 사용자의 위치 권한을 요청하고, 현재 위치를 효율적으로 가져오는 기능을 제공합니다.
/// 위치 정보는 캐시되어 불필요한 GPS 요청을 줄입니다.
@MainActor
class LocationPermissionService: NSObject {

    @MainActor static let shared = LocationPermissionService()

    // 싱글톤 인스턴스 - 앱 전체에서 하나의 인스턴스만 사용
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

    /// 위치 매니저의 기본 설정을 구성합니다.
    ///
    /// - 정확도: 100미터
    /// - 거리 필터: 500미터 (500m 이상 이동할 때만 업데이트)
    private func setupLocationManager() {
        locationManager.delegate = self

        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 500
    }

    /// 캐시된 위치가 아직 유효한지 확인합니다.
    ///
    /// - Returns: 유효한 캐시 위치가 있으면 `CLLocation`, 없으면 `nil`
    private func getCachedLocationIfAvailable() -> CLLocation? {
        guard let cachedLocation = cachedLocation,
              let lastTime = lastLocationTime,
              Date().timeIntervalSince(lastTime) < locationCacheValidDuration else {
            return nil
        }
        return cachedLocation
    }

    /// 현재 위치를 가져옵니다.
    ///
    /// - Returns: 현재 위치 정보 또는 `nil` (권한이 없거나 실패한 경우)
    ///
    /// ## 동작 방식
    /// 1. 위치 권한이 있는지 먼저 확인
    /// 2. 캐시된 위치가 유효하면 즉시 반환
    /// 3. 이미 위치 요청 중이면 캐시된 위치라도 반환
    /// 4. 새로 GPS로 위치 요청
    func getCurrentLocation() async -> CLLocation? {
        guard checkCurrentPermissionStatus() else {

            return nil
        }

        if let cachedLocation = getCachedLocationIfAvailable() {

            return cachedLocation
        }

        if locationContinuation != nil {

            return cachedLocation
        }

        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()
        }
    }

    /// 위치 권한을 요청합니다.
    ///
    /// - Returns: 권한이 허용되면 `true`, 거부되면 `false`
    func requestLocationPermission() async -> Bool {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:

            return await withCheckedContinuation { continuation in
                self.permissionContinuation = continuation
                locationManager.requestWhenInUseAuthorization()
            }

        case .denied, .restricted:

            return false

        case .authorizedWhenInUse, .authorizedAlways:

            return true

        @unknown default:

            return false
        }
    }

    /// 현재 위치 권한 상태를 확인합니다.
    ///
    /// - Returns: 위치 사용 권한이 있으면 `true`, 없으면 `false`
    func checkCurrentPermissionStatus() -> Bool {
        let status = locationManager.authorizationStatus
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }

    /// 위치 권한이 아직 결정되지 않았는지 확인합니다.
    ///
    /// - Returns: 권한이 결정되지 않았으면 `true`, 이미 결정되었으면 `false`
    func isPermissionNotDetermined() -> Bool {
        return locationManager.authorizationStatus == .notDetermined
    }
}

// MARK: - CLLocationManagerDelegate
// 위치 관련 이벤트를 처리하는 확장

extension LocationPermissionService: CLLocationManagerDelegate {

    /// 위치 업데이트를 처리합니다.
    ///
    /// HealthKit에서 위치 정보를 받았을 때 호출되는 메서드입니다.
    /// 받은 위치를 캐시하고 대기 중인 요청에 응답합니다.
    ///
    /// - Parameters:
    ///  - manager: 위치 매니저 인스턴스
    ///  - locations: 업데이트된 위치 정보 배열
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        Task { @MainActor in
            guard let location = locations.last else { return }

            self.cachedLocation = location
            self.lastLocationTime = Date()
            self.locationContinuation?.resume(returning: location)
            self.locationContinuation = nil
        }
    }

    /// 위치 요청 실패를 처리합니다.
    ///
    /// GPS 신호가 약하거나 기타 이유로 위치를 가져올 수 없을 때 호출됩니다.
    ///
    /// - Parameters:
    ///   - manager: 위치 매니저 인스턴스
    ///   - error: 발생한 오류 정보
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in

            // 대기 중인 continuation에 nil 전달
            self.locationContinuation?.resume(returning: nil)
            self.locationContinuation = nil
        }
    }

    /// 위치 권한 상태 변경을 처리합니다.
    ///
    /// 사용자가 설정에서 위치 권한을 변경하거나, 권한 요청에 응답했을 때 호출됩니다.
    ///
    /// - Parameters:
    ///   - manager: 위치 매니저 인스턴스
    ///   - status: 새로운 권한 상태
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.permissionContinuation?.resume(returning: true)

            case .denied, .restricted:
                self.permissionContinuation?.resume(returning: false)

            case .notDetermined:
                break

            @unknown default:
                self.permissionContinuation?.resume(returning: false)
            }

            // continuation 초기화
            self.permissionContinuation = nil
        }
    }
}
