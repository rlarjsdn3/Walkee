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

    // 거리 업데이트 콜백
    var onDistanceUpdated: ((String, String) -> Void)?  // (gpxURL, distanceText)
    var onAllDistancesError: ((String) -> Void)?        // (errorMessage)

    // 모든 코스의 거리를 한 번에 계산
    func calculateAllCourseDistances(courses: [WalkingCourse]) async {

        // 내 위치 한 번만 가져오기
        guard let myLocation = await LocationPermissionService.shared.getCurrentLocation() else {
            await MainActor.run {
                // 모든 코스에 에러 상태를 캐시에 저장
                let errorMessage = "위치 권한 없음"
                for course in courses {
                    courseDistances[course.gpxpath] = errorMessage
                }
                onAllDistancesError?(errorMessage)
            }
            return
        }

        // 각 코스별로 거리 계산
        for course in courses {
            Task {
                await calculateSingleCourseDistance(course: course, myLocation: myLocation)
            }
        }
    }

    // 개별 코스 거리 계산

    private func calculateSingleCourseDistance(course: WalkingCourse, myLocation: CLLocation) async {
        // GPX에서 첫 번째 좌표 가져오기
        guard let firstCoordinate = await WalkingCourseService.shared.getFirstCoordinate(from: course.gpxpath) else {
            updateCourseDistance(gpxURL: course.gpxpath, distanceText: "네트워크 오류")
            return
        }

        // 거리 계산
        let courseLocation = CLLocation(latitude: firstCoordinate.latitude, longitude: firstCoordinate.longitude)
        let distanceInKm = myLocation.distance(from: courseLocation) / 1000.0

        // 거리 텍스트 포맷팅
        let distanceText = formatDistance(distanceInKm)

        // 결과 저장 및 UI 업데이트
        updateCourseDistance(gpxURL: course.gpxpath, distanceText: distanceText)
    }

    // 특정 코스의 거리 업데이트
    private func updateCourseDistance(gpxURL: String, distanceText: String) {
        // 결과 저장
        courseDistances[gpxURL] = distanceText

        // 뷰컨트롤러에 알림
        onDistanceUpdated?(gpxURL, distanceText)
    }

    // 캐시된 거리 가져오기
    func getCachedDistance(for gpxURL: String) -> String? {
        return courseDistances[gpxURL]
    }

    // 거리 포맷팅
    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1.0 {
            return "\(String(format: "%.1f", distance))km"
        } else {
            return "\(Int(distance * 1000))m"
        }
    }
}
