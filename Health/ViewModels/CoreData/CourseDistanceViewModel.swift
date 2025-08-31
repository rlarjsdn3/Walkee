//
//  CourseDistanceViewModel.swift
//  Health
//
//  Created by juks86 on 8/16/25.
//

import UIKit
import CoreLocation

/// 추천 걷기 코스와 사용자 위치 간의 거리를 계산하고 관리하는 ViewModel 클래스
///
/// 이 클래스는 여러 산책 코스에 대해 사용자의 현재 위치와의 거리를 비동기로 계산합니다.
/// 위치 권한과 네트워크 상태를 체크하여 적절한 에러 메시지를 표시하고,
/// 병렬 처리를 통해 성능을 최적화합니다.
@MainActor
class CourseDistanceViewModel {

    // 거리 계산 결과 저장
    private var courseDistances: [String: String] = [:]

    /// 위치 서비스 인스턴스 (권한 체크 및 현재 위치 가져오기용)
    private let locationService = LocationPermissionService.shared

    // 개별 코스 거리가 업데이트될 때마다 호출됩니다.
    var onDistanceUpdated: ((String, String) -> Void)?  // (gpxURL, distanceText)

    // 캐시가 통째로 변경되어 전체 UI를 새로고침해야 할 때 호출됩니다.
    var onCacheNeedsRefresh: (() -> Void)?

    /// 여러 산책 코스에 대해 거리를 계산하고 결과를 캐시합니다.
    ///
    /// - Parameters:
    ///   - courses: 거리를 계산할 산책 코스 배열
    ///   - isNetworkAvailable: 네트워크 연결 상태 (기본값: true)
    ///
    func prepareAndCalculateDistances(for courses: [WalkingCourse], isNetworkAvailable: Bool = true) async {

        guard isNetworkAvailable else {
            for course in courses {
                courseDistances[course.gpxpath] = "네트워크 오류"
                onDistanceUpdated?(course.gpxpath, "네트워크 오류")
            }
            return
        }

        // 권한 확인
        guard locationService.checkCurrentPermissionStatus() else {

            // 권한이 없으면 "위치 권한 없음"을 캐시에 저장하고 즉시 종료
            for course in courses {
                courseDistances[course.gpxpath] = "위치 권한 없음"
                onDistanceUpdated?(course.gpxpath, "위치 권한 없음")
            }
            return
        }

        guard let myLocation = await getMyLocationWithRetry() else {

            let errorMessage = "위치 신호 오류"
            for course in courses {
                courseDistances[course.gpxpath] = errorMessage
                onDistanceUpdated?(course.gpxpath, errorMessage)
            }
            return
        }

        await calculateDistancesConcurrently(for: courses, from: myLocation)
        onCacheNeedsRefresh?() // 최종 결과를 표시하기 위해 UI 갱신 신호
    }

    /// GPS 웜업 시간을 고려하여 현재 위치를 가져옵니다.
    ///
    /// - Returns: 현재 위치 정보 또는 `nil` (두 번의 시도 모두 실패한 경우)
    ///
    private func getMyLocationWithRetry() async -> CLLocation? {
        if let location = await locationService.getCurrentLocation() {
            return location
        } else {
            // 첫 시도 실패 시 1.5초 후 재시도
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            return await locationService.getCurrentLocation()
        }
    }

    /// 여러 코스의 거리를 병렬로 계산합니다.
    ///
    /// - Parameters:
    ///   - courses: 거리를 계산할 코스 배열
    ///   - myLocation: 사용자의 현재 위치
    ///
    /// ## 성능 최적화
    /// `TaskGroup`을 사용하여 모든 코스의 거리를 동시에 계산합니다.
    /// 각 코스는 독립적으로 처리되므로 병렬 처리가 효과적입니다.
    ///
    /// 개별 코스 계산이 완료될 때마다 `onDistanceUpdated` 콜백이 호출되어
    /// 사용자가 결과를 즉시 확인할 수 있습니다.
    private func calculateDistancesConcurrently(for courses: [WalkingCourse], from myLocation: CLLocation) async {
        await withTaskGroup(of: Void.self) { group in
            for course in courses {
                group.addTask {
                    await self.calculateSingleCourseDistance(course: course, myLocation: myLocation)
                }
            }
        }
    }

    /// 단일 코스와 사용자 위치 간의 거리를 계산합니다.
    ///
    /// - Parameters:
    ///   - course: 거리를 계산할 산책 코스
    ///   - myLocation: 사용자의 현재 위치
    ///
    private func calculateSingleCourseDistance(course: WalkingCourse, myLocation: CLLocation) async {
        guard let firstCoordinate = await WalkingCourseService.shared.getFirstCoordinate(from: course.gpxpath) else {
            updateCourseDistance(gpxURL: course.gpxpath, distanceText: "네트워크 오류")
            return
        }
        let courseLocation = CLLocation(latitude: firstCoordinate.latitude, longitude: firstCoordinate.longitude)
        let distanceInMeters = myLocation.distance(from: courseLocation)
        let distanceText = formatDistance(distanceInMeters)
        updateCourseDistance(gpxURL: course.gpxpath, distanceText: distanceText)
    }

    /// 계산된 거리를 캐시에 저장하고 UI 업데이트 콜백을 호출합니다.
    ///
    /// - Parameters:
    ///   - gpxURL: GPX 파일의 URL (캐시 키로 사용)
    ///   - distanceText: 포맷된 거리 텍스트
    private func updateCourseDistance(gpxURL: String, distanceText: String) {
        courseDistances[gpxURL] = distanceText
        onDistanceUpdated?(gpxURL, distanceText)
    }

    /// 특정 GPX URL에 대해 캐시된 거리 정보를 반환합니다.
    func getCachedDistance(for gpxURL: String) -> String? {
        return courseDistances[gpxURL]
    }

    /// 모든 캐시된 거리 데이터를 삭제합니다.
    ///
    /// 위치 권한 상태가 변경되거나 새로운 계산이 필요할 때 호출하여
    /// 이전 결과를 모두 제거합니다.
    func clearDistanceCache() {
        courseDistances.removeAll()
    }

    /// 거리를 사용자 친화적인 형태로 포맷합니다.
    ///
    /// - Parameter distance: 미터 단위의 거리값
    /// - Returns: 포맷된 거리 문자열
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance >= 1000.0 {
            let distanceInKm = distance / 1000.0
            return "\(String(format: "%.1f", distanceInKm))km"
        } else {
            return "\(Int(distance))m"
        }
    }
}
