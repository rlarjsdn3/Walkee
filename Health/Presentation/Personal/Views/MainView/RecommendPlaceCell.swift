//
//  RecommendPlaceCell.swift
//  Health
//
//  Created by juks86 on 8/7/25.
//

import UIKit
import MapKit

protocol RecommendPlaceCellDelegate: AnyObject {
    func didTapInfoButton(for course: WalkingCourse)
    func didTapCell(for course: WalkingCourse)
}

class RecommendPlaceCell: CoreCollectionViewCell {
    private var skeletonView: SkeletonView!

    @IBOutlet weak var placeBackground: UIView!
    @IBOutlet weak var courseImage: UIImageView!
    @IBOutlet weak var courseNameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var userDistanceLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var levelImage: UIImageView!
    @IBOutlet weak var infoButton: InfoDetailButton!

    private var currentGPXURL: String?
    private var thumbnailTask: Task<Void, Never>?
    weak var delegate: RecommendPlaceCellDelegate?
    private var currentCourse: WalkingCourse?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupTapGesture()
    }

    override func setupAttribute() {
        super.setupAttribute()
        setupInfoButton()
        setupSkeletonView()
        BackgroundHeightUtils.setupShadow(for: self)
        BackgroundHeightUtils.setupDarkModeBorder(for: placeBackground)
        placeBackground.applyCornerStyle(.medium)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentGPXURL = nil
        delegate = nil
        currentCourse = nil

        //이전 Task 취소 (메모리 누수 방지)
        thumbnailTask?.cancel()
        showSkeletonView()
    }

    // API에서 받은 실제 데이터로 설정
    func configure(with course: WalkingCourse, isNetworkAvailable: Bool = true) {
        self.currentCourse = course
        // 기본 텍스트 설정
        courseNameLabel.text = course.crsKorNm.upToFirstCourse()
        locationLabel.text = course.sigun
        showSkeletonView()
        let distance = NSAttributedString(string: "\(course.crsDstnc)km")
            .font(UIFont.preferredFont(forTextStyle: .footnote), to: "km")
        distanceLabel.attributedText = distance
        durationLabel.attributedText = course.crsTotlRqrmHour.toFormattedDuration()
        // 난이도 텍스트와 이미지 색상 동시 설정
        let levelInfo = getLevelInfo(from: course.crsLevel)
        levelLabel.text = levelInfo.text
        levelImage.tintColor = levelInfo.color

        currentGPXURL = course.gpxpath
        thumbnailTask?.cancel()

        // 네트워크 오류 시 무조건 기본 이미지 표시
        if !isNetworkAvailable {
            hideSkeletonView()
            let config = UIImage.SymbolConfiguration(pointSize: 52) // 원하는 크기와 굵기
            courseImage.image = UIImage(systemName: "mappin.slash.circle", withConfiguration: config)
            courseImage.tintColor = .systemGray3
            courseImage.contentMode =  .center
            return
        }

        // 캐시 먼저 확인
        if let cachedImage = WalkingCourseService.shared.getCachedThumbnail(for: course.gpxpath) {
            courseImage.image = cachedImage
            hideSkeletonView()
            return
        }

        // 썸네일만 별도 처리 (거리는 뷰컨트롤러에서 처리)
        thumbnailTask = Task { @MainActor in
            let image = await WalkingCourseService.shared.generateThumbnailAsync(from: course.gpxpath)

            guard currentGPXURL == course.gpxpath else { return }

            hideSkeletonView()

            if let image = image {
                courseImage.image = image
                courseImage.contentMode = .scaleAspectFill
                hideSkeletonView()
            } else {
                courseImage.image = nil
                let config = UIImage.SymbolConfiguration(pointSize: 52)
                courseImage.image = UIImage(systemName: "mappin.slash.circle", withConfiguration: config)
                courseImage.tintColor = .systemGray3
                courseImage.contentMode = .center
                return
            }
        }
    }

    func updateDistance(_ distanceText: String) {
        userDistanceLabel.text = distanceText

        if distanceText.contains("km") || distanceText.contains("m") {
            userDistanceLabel.textColor = .systemBlue
        } else {
            userDistanceLabel.textColor = .systemBlue
        }
    }

    // 난이도 변환 함수
    func getLevelInfo(from level: String) -> (text: String, color: UIColor) {
        switch level {
        case "1":
            return ("쉬움", .systemYellow) // 쉬움: 노란색
        case "2":
            return ("보통", .systemOrange) // 보통: 주황색
        case "3":
            return ("어려움", .systemRed)   // 어려움: 빨간색
        default:
            return ("알 수 없음", .systemGray) // 그 외: 회색
        }
    }

    private func setupInfoButton() {
        infoButton.touchHandler = { [weak self] _ in
            guard let self = self, let course = self.currentCourse else { return }
            self.delegate?.didTapInfoButton(for: course)
        }

        // 기존 configuration을 가져와서 색상만 변경
        if var config = infoButton.configuration {
            config.image = UIImage(systemName: "info.circle.fill")?
                .applyingSymbolConfiguration(.init(paletteColors: [.darkGray]))
            infoButton.configuration = config
        }
    }

    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        self.addGestureRecognizer(tapGesture)
        self.isUserInteractionEnabled = true
    }

    @objc private func cellTapped() {
        guard let course = currentCourse else { return }
        delegate?.didTapCell(for: course)
    }

    private func setupSkeletonView() {
        skeletonView = SkeletonView()
        skeletonView?.translatesAutoresizingMaskIntoConstraints = false
        courseImage.addSubview(skeletonView!)

        NSLayoutConstraint.activate([
            skeletonView!.topAnchor.constraint(equalTo: courseImage.topAnchor),
            skeletonView!.leadingAnchor.constraint(equalTo: courseImage.leadingAnchor),
            skeletonView!.trailingAnchor.constraint(equalTo: courseImage.trailingAnchor),
            skeletonView!.bottomAnchor.constraint(equalTo: courseImage.bottomAnchor)
        ])
    }

    // 로딩 시작
    private func showSkeletonView() {
        skeletonView?.isHidden = false
        skeletonView?.startAnimating()
    }

    // 로딩 완료
    private func hideSkeletonView() {
        skeletonView?.isHidden = true
        skeletonView?.stopAnimating()
    }
}

extension String {

    //소요시간 포맷팅
    func toFormattedDuration() -> NSAttributedString {
        let minutes = Int(self)!
        let hours = minutes / 60
        let mins = minutes % 60

        let formattedString: String

        if hours > 0 && mins > 0 {
            formattedString = "\(hours)시간 \(mins)분"
        } else if hours > 0 {
            formattedString = "\(hours)시간"
        } else {
            formattedString = "\(mins)분"
        }

        let attributedString = NSAttributedString(string: formattedString)

        // 단위 부분에 footnote 폰트 적용
        let footnoteFont = UIFont.preferredFont(forTextStyle: .footnote)
        var result = attributedString
        result = result.font(footnoteFont, to: "시간")
        result = result.font(footnoteFont, to: "분")

        return result
    }

    // 첫 번째 "코스"까지만 반환
    func upToFirstCourse() -> String {
        if let range = self.range(of: "코스") {
            let endIndex = self.index(range.upperBound, offsetBy: 0)
            return String(self[..<endIndex])
        }
        return self
    }
}
