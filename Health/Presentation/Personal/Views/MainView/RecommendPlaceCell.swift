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
        distanceLabel.text = course.crsDstnc
        durationLabel.text = course.crsTotlRqrmHour

        // 로딩 이미지
        courseImage.image = UIImage(systemName: "map")
        courseImage.tintColor = .systemGray3

        currentGPXURL = course.gpxpath

        // 이전 Task 취소
        thumbnailTask?.cancel()

        // 새로운 Task 시작 (Swift Concurrency)
        thumbnailTask = Task { @MainActor in
            let image = await WalkingCourseService.shared.generateThumbnailAsync(from: course.gpxpath)

            // 셀이 재사용되었는지 확인
            guard currentGPXURL == course.gpxpath else { return }

            if let image = image {
                courseImage.image = image
                courseImage.contentMode = .scaleAspectFill
            } else {
                courseImage.image = UIImage(systemName: "location.slash")
                courseImage.tintColor = .systemOrange
            }
        }
    }
}
