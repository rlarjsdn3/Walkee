//
//  SkeletonView.swift
//  Health
//
//  Created by juks86 on 8/25/25.
//

import UIKit

class SkeletonView: UIView {

    private let gradientLayer = CAGradientLayer()
    private let iconImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSkeletonView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSkeletonView()
    }

    private func setupSkeletonView() {
        backgroundColor = UIColor.systemGray4

        // 그라데이션 레이어 설정
        gradientLayer.colors = [
            UIColor.systemGray4.cgColor,
            UIColor.systemGray3.cgColor,
            UIColor.systemGray4.cgColor
        ]
        gradientLayer.locations = [0, 0.5, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)

        layer.addSublayer(gradientLayer)

        // SF 심볼 설정
        setupIconImageView()
    }

    private func setupIconImageView() {
        iconImageView.image = UIImage(named: "destination") //
        iconImageView.tintColor = UIColor.systemGray
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

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func startAnimating() {
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: "shimmer")
    }

    func stopAnimating() {
        gradientLayer.removeAnimation(forKey: "shimmer")
    }
}
