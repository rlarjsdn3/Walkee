//
//  CourseDistanceViewModel.swift
//  Health
//
//  Created by juks86 on 8/16/25.
//

import UIKit
import CoreLocation

@MainActor
class CourseDistanceViewModel {

    // 거리 계산 결과 저장
    private var courseDistances: [String: String] = [:]
    private let locationService = LocationPermissionService.shared
    // 거리 업데이트 콜백
    var onDistanceUpdated: ((String, String) -> Void)?  // (gpxURL, distanceText)
    // 개별 코스 거리가 업데이트될 때마다 호출됩니다.

    // 캐시가 통째로 변경되어 전체 UI를 새로고침해야 할 때 호출됩니다.
    var onCacheNeedsRefresh: (() -> Void)?

    // 거리 계산을 준비하는 메서드
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

    // GPS 웜업 시간을 고려하여, 실패 시 잠시 후 한 번 더 시도하는 함수
    private func getMyLocationWithRetry() async -> CLLocation? {
        if let location = await locationService.getCurrentLocation() {
            return location
        } else {
            // 첫 시도 실패 시 1.5초 후 재시도
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            return await locationService.getCurrentLocation()
        }
    }

    // 여러 코스의 거리를 동시에 계산하는 내부 헬퍼 함수
    private func calculateDistancesConcurrently(for courses: [WalkingCourse], from myLocation: CLLocation) async {
        await withTaskGroup(of: Void.self) { group in
            for course in courses {
                group.addTask {
                    await self.calculateSingleCourseDistance(course: course, myLocation: myLocation)
                }
            }
        }
    }

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

    private func updateCourseDistance(gpxURL: String, distanceText: String) {
        courseDistances[gpxURL] = distanceText
        onDistanceUpdated?(gpxURL, distanceText)
    }

    func getCachedDistance(for gpxURL: String) -> String? {
        return courseDistances[gpxURL]
    }

    func clearDistanceCache() {
        courseDistances.removeAll()
    }


    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance >= 1000.0 {
            let distanceInKm = distance / 1000.0
            return "\(String(format: "%.1f", distanceInKm))km"
        } else {
            return "\(Int(distance))m"
        }
    }
}
