//
//  ProgressIndicatorView.swift
//  Health
//
//  Created by 권도현 on 8/5/25.
//

import UIKit

/// 여러 페이지로 구성된 온보딩/튜토리얼 등의 진행 상태를 시각적으로 표시하는 `UIStackView`
///
/// - 각 페이지에 해당하는 막대(Bar)를 균등하게 나열한다.
/// - `updateProgress(to:)` 메서드를 통해 전체 진행률(`0.0 ~ 1.0`)에 따라
///   각 막대의 채워진 비율을 갱신한다.
///
/// 예: 총 5페이지 중 40% 진행 시 → 앞 2개 막대는 가득 채워지고,
///     세 번째 막대는 50% 정도 채워짐.
class ProgressIndicatorStackView: UIStackView {
    
    // - Properties
    
    /// 전체 페이지 개수 (막대 개수와 동일)
    private let totalPages: Int
    
    /// 각 막대의 높이
    private let barHeight: CGFloat
    
    /// 비활성 상태(배경 막대)의 색상
    private let backgroundBarColor: UIColor
    
    /// 진행 상태(채워지는 부분)의 색상
    private let fillColor: UIColor

    // - Initializer
    
    /// 진행 표시기를 초기화한다.
    ///
    /// - Parameters:
    ///   - totalPages: 전체 페이지 수 (막대 개수)
    ///   - barHeight: 각 막대의 높이 (기본값 4pt)
    ///   - backgroundBarColor: 비활성 막대 색상 (기본값 `.buttonBackground`)
    ///   - fillColor: 진행 막대 색상 (기본값 `.accent`)
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
        
        // StackView 기본 속성 설정
        self.axis = .horizontal
        self.spacing = 6
        self.distribution = .fillEqually
        
        setupInitialIndicators()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // - Setup
    
    /// 초기 막대(배경 바)들을 생성하여 StackView에 추가한다.
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

    // - Update
    
    /// 진행률을 업데이트하여 막대들을 채운다.
    ///
    /// - Parameter progress: 진행률 (`0.0` ~ `1.0`)
    ///
    /// 진행률 계산 방식:
    /// - 전체 페이지 개수 × 진행률 = 총 채워야 할 진행량
    /// - 각 막대에 대해:
    ///   - 이미 지난 막대는 100% 채움
    ///   - 현재 진행 중인 막대는 일부만 채움
    ///   - 이후 막대는 0% 유지
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

            // 각 막대의 채움 비율 계산
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
