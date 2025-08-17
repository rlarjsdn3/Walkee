//
//  AlanLoadingIndicatorView.swift
//  Health
//
//  Created by 김건우 on 8/14/25.
//

import UIKit

final class AlanLoadingIndicatorView: CoreView {

    /// 로딩 인디케이터의 현재 상태를 나타내는 열거형입니다.
    enum State {
        /// 작업이 진행 중인 상태
        case loading
        /// 작업이 실패한 상태
        case failed
        /// 데이터 접근 권한이 없는 상태
        case denied
        /// 작업이 성공적으로 완료된 상태
        case success
    }

    private let exclamationMarkImageView = UIImageView()
    private let loadingIndicatorView = CustomActivityIndicatorView()
    private let titleLabel = UILabel()
    private let indicatorStackView = UIStackView()
    
    private(set) var state: State = .loading
    private var timer: Timer?
    private var count: Int = 0

    private let doingSummaryText = "AI가 열심히 요약 중이예요."
    private let deniedSummaryText = "AI가 요약에 실패했어요. 건강 데이터에 대한 접근 권한이 필요합니다."
    private let failedSummaryText = "AI가 요약에 실패했어요. 잠시 후 다시 시도해주세요."

    override func setupHierarchy() {
        addSubview(indicatorStackView)
        indicatorStackView.addArrangedSubviews(loadingIndicatorView, titleLabel)
    }

    override func setupAttribute() {
        loadingIndicatorView.color = .accent
        loadingIndicatorView.dotDiameter = 24
        loadingIndicatorView.startAnimating()

        titleLabel.text = doingSummaryText
        titleLabel.textColor = .secondaryLabel
        titleLabel.numberOfLines = 0

        indicatorStackView.spacing = 8
        indicatorStackView.alignment = .top
        indicatorStackView.translatesAutoresizingMaskIntoConstraints = false

        exclamationMarkImageView.image = exclamationmarkCircleImage([.systemRed])
        exclamationMarkImageView.translatesAutoresizingMaskIntoConstraints = false
        
        setState(state)
    }

    override func setupConstraints() {
        NSLayoutConstraint.activate([
            indicatorStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            indicatorStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            indicatorStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            indicatorStackView.topAnchor.constraint(equalTo: topAnchor)
        ])
        
        NSLayoutConstraint.activate([
            exclamationMarkImageView.widthAnchor.constraint(equalToConstant: 24),
            exclamationMarkImageView.heightAnchor.constraint(equalTo: exclamationMarkImageView.widthAnchor, multiplier: 1.0)
        ])
    }

    deinit {
        MainActor.assumeIsolated {
            stopTimer()
        }
    }
}

extension AlanLoadingIndicatorView {

    /// 로딩 인디케이터의 상태를 변경합니다.
    ///
    /// 전달된 상태 값에 따라 내부 UI를 해당 상태에 맞게 업데이트합니다.
    ///
    /// - Parameter new: 변경할 `AlanLoadingIndicatorView.State` 값.
    ///   - `.loading`: 로딩 중 상태로 전환합니다.
    ///   - `.failed`: 실패 상태로 전환합니다.
    ///   - `.sucess`: 성공 상태로 전환합니다.
    func setState(_ new: AlanLoadingIndicatorView.State) {
        switch new {
        case .loading: setLoadingState()
        case .failed:  setFailedState()
        case .denied:  setDeniedState()
        case .success: setSuccessState()
        }
    }

    private func setLoadingState() {
        state = .loading
        exclamationMarkImageView.removeFromSuperview()
        indicatorStackView.insertArrangedSubview(loadingIndicatorView, at: 0)
        indicatorStackView.spacing = 6
        titleLabel.text = doingSummaryText
        startTimer()
    }

    private func setFailedState() {
        state = .failed
        loadingIndicatorView.removeFromSuperview()
        exclamationMarkImageView.image = exclamationmarkCircleImage([.systemRed])
        indicatorStackView.insertArrangedSubview(exclamationMarkImageView, at: 0)
        indicatorStackView.spacing = 8
        titleLabel.text = failedSummaryText
        stopTimer()
    }
    
    private func setDeniedState() {
        state = .denied
        loadingIndicatorView.removeFromSuperview()
        exclamationMarkImageView.image = exclamationmarkCircleImage([.systemYellow])
        indicatorStackView.insertArrangedSubview(exclamationMarkImageView, at: 0)
        indicatorStackView.spacing = 8
        titleLabel.text = deniedSummaryText
        stopTimer()
    }

    private func setSuccessState() {
        state = .success
        isHidden = true
        stopTimer()
    }
}

fileprivate extension AlanLoadingIndicatorView {

    func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.33, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.count += 1
                let newText = self.doingSummaryText + Array(repeating: ".", count: self.count % 3).joined()
                self.titleLabel.text = newText
            }
        }
    }

    func stopTimer() {
        count = 0
        timer?.invalidate()
        timer = nil
    }
}

fileprivate extension AlanLoadingIndicatorView {
    
    private func exclamationmarkCircleImage(_ paletteColors: [UIColor]) -> UIImage? {
        let image = UIImage(systemName: "exclamationmark.circle.fill")
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
            .applying(UIImage.SymbolConfiguration(paletteColors: paletteColors))
        return image?.applyingSymbolConfiguration(config)
    }
}
