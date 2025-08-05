//
//  ProgressIndicatorView.swift
//  Health
//
//  Created by 권도현 on 8/5/25.
//


import UIKit

class ProgressIndicatorView: UIStackView {
    
    private let totalPages: Int
    private let barHeight: CGFloat
    private let backgroundBarColor: UIColor
    private let fillColor: UIColor

    init(
        totalPages: Int,
        barHeight: CGFloat = 4,
        backgroundBarColor: UIColor = .buttonBackground,
        fillColor: UIColor = .accent
    ) {
        self.totalPages = totalPages
        self.barHeight = barHeight
        self.backgroundBarColor = backgroundBarColor
        self.fillColor = fillColor
        super.init(frame: .zero)
        self.axis = .horizontal
        self.spacing = 6
        self.distribution = .fillEqually
        setupInitialIndicators()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupInitialIndicators() {
        for _ in 0..<totalPages {
            let containerView = UIView()
            containerView.backgroundColor = backgroundBarColor
            containerView.layer.cornerRadius = barHeight / 2
            containerView.clipsToBounds = true
            self.addArrangedSubview(containerView)

            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.heightAnchor.constraint(equalToConstant: barHeight).isActive = true
        }
    }

    func updateProgress(to progress: CGFloat) {
        let clampedProgress = max(0, min(progress, 1))
        let totalProgress = CGFloat(totalPages) * clampedProgress

        for (i, view) in self.arrangedSubviews.enumerated() {
            
            let containerView = view
            containerView.subviews.forEach { $0.removeFromSuperview() }

            let progressBar = UIView()
            progressBar.backgroundColor = fillColor
            progressBar.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(progressBar)

            let fillRatio: CGFloat
            if totalProgress > CGFloat(i + 1) {
                fillRatio = 1.0
            } else if totalProgress > CGFloat(i) {
                fillRatio = totalProgress - CGFloat(i)
            } else {
                fillRatio = 0.0
            }

            NSLayoutConstraint.activate([
                progressBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                progressBar.topAnchor.constraint(equalTo: containerView.topAnchor),
                progressBar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                progressBar.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: fillRatio)
            ])
        }
    }
}
