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
    @IBOutlet weak var levelLabel: UILabel!

    private var currentGPXURL: String?
    private var thumbnailTask: Task<Void, Never>?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setupAttribute() {
        super.setupAttribute()
        CustomLightModeBoxConstraint.setupShadow(for: self)
        CustomLightModeBoxConstraint.setupDarkModeBorder(for: placeBackground)
        placeBackground.applyCornerStyle(.medium)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        courseImage.image = nil
        currentGPXURL = nil
        
        //이전 Task 취소 (메모리 누수 방지)
        thumbnailTask?.cancel()
    }
    
    // API에서 받은 실제 데이터로 설정
    func configure(with course: WalkingCourse) {
        // 기본 텍스트 설정
        courseNameLabel.text = course.crsKorNm
        locationLabel.text = course.sigun
        distanceLabel.text = "\(course.crsDstnc)km"
        durationLabel.text = course.crsTotlRqrmHour.toFormattedDuration()
        levelLabel.text = course.crsLevel

        // 기본 로딩 상태
        courseImage.image = UIImage(systemName: "map")
        courseImage.tintColor = .systemGray3
        
        currentGPXURL = course.gpxpath
        thumbnailTask?.cancel()
        
        // 썸네일만 별도 처리 (거리는 뷰컨트롤러에서 처리)
        thumbnailTask = Task { @MainActor in
            let image = await WalkingCourseService.shared.generateThumbnailAsync(from: course.gpxpath)
            
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
    
    func updateDistance(_ distanceText: String) {
        userDistanceLabel.text = distanceText
        
        if distanceText.contains("km") || distanceText.contains("m") {
            userDistanceLabel.textColor = .systemBlue
        } else {
            userDistanceLabel.textColor = .systemOrange
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
