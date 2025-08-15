//
//  RecommendPlaceCell.swift
//  Health
//
//  Created by juks86 on 8/7/25.
//

import UIKit
import MapKit

class RecommendPlaceCell: CoreCollectionViewCell {

    @IBOutlet weak var placeBackground: UIView!
    @IBOutlet weak var courseImage: UIImageView!
    @IBOutlet weak var courseNameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var userDistanceLabel: UILabel!

    private var currentGPXURL: String?
    private var thumbnailTask: Task<Void, Never>?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setupAttribute() {
        super.setupAttribute()
        placeBackground.applyCornerStyle(.medium)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        courseImage.image = nil
        currentGPXURL = nil
        thumbnailTask?.cancel()
    }

    // API에서 받은 실제 데이터로 설정
    func configure(with course: WalkingCourse) {
        // 텍스트 설정
        courseNameLabel.text = course.crsKorNm
        locationLabel.text = course.sigun
        distanceLabel.text = "\(course.crsDstnc)km"
        durationLabel.text = course.crsTotlRqrmHour.toFormattedDuration()

        // 로딩 이미지
        courseImage.image = UIImage(systemName: "map")
        courseImage.tintColor = .systemGray3

        // 거리 로딩 표시 추가
        userDistanceLabel.text = "거리측정중..."
        userDistanceLabel.textColor = .systemGray

        currentGPXURL = course.gpxpath

        // 이전 Task 취소
        thumbnailTask?.cancel()

        // 한 번의 Task로 썸네일과 거리 모두 처리
        thumbnailTask = Task { @MainActor in
            // 동시에 두 작업 수행 (GPX는 한 번만 다운로드)
            async let thumbnailImage = WalkingCourseService.shared.generateThumbnailAsync(from: course.gpxpath)
            async let distanceFromMe = calculateDistance(gpxURL: course.gpxpath)

            // 두 결과 기다리기
            let image = await thumbnailImage
            let distance = await distanceFromMe

            // 셀이 재사용되었는지 확인
            guard currentGPXURL == course.gpxpath else { return }

            // 썸네일 이미지 설정
            if let image = image {
                courseImage.image = image
                courseImage.contentMode = .scaleAspectFill
            } else {
                courseImage.image = UIImage(systemName: "location.slash")
                courseImage.tintColor = .systemOrange
            }

            // 거리 설정
            if let distance = distance {
                userDistanceLabel.text = formatDistance(distance)
                userDistanceLabel.textColor = .systemBlue
            }
        }
    }

    //거리 계산 메서드
    private func calculateDistance(gpxURL: String) async -> Double? {

        //1. 위치권한 확인해서 허용하지 않으면 위치권한필요 텍스트 표시
        guard LocationPermissionService.shared.checkCurrentPermissionStatus() else {

            // 메인 스레드에서 직접 UI 업데이트
            await MainActor.run {
                userDistanceLabel.text = "위치 권한 필요"
                userDistanceLabel.textColor = .systemRed
            }
            return nil
        }

        // 2. 내 위치 가져오기
        guard let myLocation = await LocationPermissionService.shared.getCurrentLocation() else {
            return nil
        }

        // 3. GPX 첫 번째 좌표 가져오기
        guard let firstCoordinate = await getFirstCoordinate(from: gpxURL) else {
            return nil
        }

        // 4. 거리 계산해서 반환
        return calculateSimpleDistance(
            from: myLocation.coordinate,
            to: firstCoordinate
        )
    }

    //첫번째 좌표값 가져오기
    private func getFirstCoordinate(from gpxURL: String) async -> CLLocationCoordinate2D? {
        guard let url = URL(string: gpxURL) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let coordinates = await WalkingCourseService.shared.parseGPXCoordinates(from: data)
            return coordinates.first
        } catch {
            print("GPX 로드 실패: \(error)")
            return nil
        }
    }

    //내 위치와 코스와의 거리 계산
    private func calculateSimpleDistance(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)

        // 미터를 킬로미터로 변환
        return fromLocation.distance(from: toLocation) / 1000.0
    }

	//거리 텍스트 포맷팅
     func formatDistance(_ distance: Double) -> String {
        if distance >= 1.0 {
            return "\(String(format: "%.1f", distance))km"
        } else {
            return "\(Int(distance * 1000))m"
        }
    }
}

extension String {

    //소요시간 포맷팅
    func toFormattedDuration() -> String {
        let minutes = Int(self)!
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 && mins > 0 {
            return "\(hours)시간 \(mins)분"
        } else if hours > 0 {
            return "\(hours)시간"
        } else {
            return "\(mins)분"
        }
    }
}
