//
//  SkeletonView.swift
//  Health
//
//  Created by juks86 on 8/25/25.
//

import UIKit

/// 데이터 로딩 중 표시할 스켈레톤 애니메이션 뷰
///
/// 이 클래스는 콘텐츠가 로딩되는 동안 사용자에게 시각적 피드백을 제공하는 스켈레톤 UI를 구현합니다.
class SkeletonView: UIView {

    private let gradientLayer = CAGradientLayer()
    private let iconImageView = UIImageView()

    /// 프로그래밍 방식으로 뷰를 생성할 때 사용하는 초기화 메서드
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSkeletonView()
    }

    /// 스토리보드에서 뷰를 생성할 때 사용하는 초기화 메서드
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSkeletonView()
    }

    /// 다크모드/라이트모드 전환을 감지하여 그라데이션 색상을 업데이트합니다.
    ///
    /// - Parameter previousTraitCollection: 이전 trait collection
    ///
    /// 시스템 색상 모드가 변경될 때마다 자동으로 호출되어
    /// 그라데이션 색상을 현재 모드에 맞게 업데이트합니다.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateGradientColors()
        }
    }

    /// 뷰의 레이아웃이 변경될 때 그라데이션 레이어의 크기를 조정합니다.
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    /// 스켈레톤 뷰의 초기 설정을 수행합니다.
    private func setupSkeletonView() {
        backgroundColor = UIColor.systemGray4

        // 그라데이션 레이어 설정
        updateGradientColors()
        gradientLayer.locations = [0, 0.5, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)

        layer.addSublayer(gradientLayer)

        // SF 심볼 설정
        setupIconImageView()
    }

    /// 현재 색상 모드에 맞는 그라데이션 색상으로 업데이트합니다.
    private func updateGradientColors() {
        gradientLayer.colors = [
            UIColor.systemGray4.cgColor,
            UIColor.systemGray3.cgColor,
            UIColor.systemGray4.cgColor
        ]
    }

    /// 중앙에 표시될 플레이스홀더 아이콘을 설정합니다.
    private func setupIconImageView() {
        iconImageView.image = UIImage(named: "destination")
        iconImageView.tintColor = UIColor.secondaryLabel
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconImageView)

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 52),
            iconImageView.heightAnchor.constraint(equalToConstant: 52)
        ])
    }

    /// 스켈레톤 애니메이션을 시작합니다.
    ///
    /// ## 애니메이션 특성
    /// - 지속 시간: 1.5초
    /// - 반복: 무한 반복
    /// - 효과: 왼쪽에서 오른쪽으로 흐르는 shimmer 효과
    func startAnimating() {
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: "shimmer")
    }

    /// 스켈레톤 애니메이션을 중지합니다.
    func stopAnimating() {
        gradientLayer.removeAnimation(forKey: "shimmer")
    }
}
