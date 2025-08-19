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

    private let doingSummaryText = "AI가 열심히 요약 중이에요."
    private let deniedSummaryText = "AI가 요약에 실패했어요. 건강 데이터에 대한 접근 권한이 필요해요."
    private let failedSummaryText = "AI가 요약에 실패했어요. 잠시 후 다시 시도해 주세요."

    override var intrinsicContentSize: CGSize {
        guard bounds.width > 0 else {
            return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
        }

        let text: NSString = (titleLabel.attributedText?.string as NSString?) ??
                             (titleLabel.text as NSString? ?? "")
        let font = titleLabel.font ?? UIFont.preferredFont(forTextStyle: .subheadline)

        let width = max(0, bounds.width
                        - 20  // 왼쪽 아이콘의 너비
                        - 8)  // 스택의 간격(spacing)

        let rect = text.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return CGSize(width: UIView.noIntrinsicMetric, height: ceil(rect.height - 2))
    }

    override func setupHierarchy() {
        addSubview(indicatorStackView)
        indicatorStackView.addArrangedSubviews(loadingIndicatorView, exclamationMarkImageView, titleLabel)
    }

    override func setupAttribute() {
        loadingIndicatorView.color = .accent
        loadingIndicatorView.dotDiameter = 20

        titleLabel.text = doingSummaryText
        titleLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleLabel.textColor = .secondaryLabel
        titleLabel.numberOfLines = 0

        indicatorStackView.spacing = 8
        indicatorStackView.alignment = .fill
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
            exclamationMarkImageView.widthAnchor.constraint(equalToConstant: 20),
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
        loadingIndicatorView.startAnimating()
        loadingIndicatorView.isHidden = false
        exclamationMarkImageView.isHidden = true
        indicatorStackView.spacing = 6
        indicatorStackView.alignment = .fill
        titleLabel.text = doingSummaryText
        startTimer()
        invalidateIntrinsicContentSize()
    }

    private func setFailedState() {
        state = .failed
        loadingIndicatorView.stopAnimating()
        loadingIndicatorView.isHidden = true
        exclamationMarkImageView.image = exclamationmarkCircleImage([.systemRed])
        exclamationMarkImageView.isHidden = false
        indicatorStackView.spacing = 8
        indicatorStackView.alignment = .top
        titleLabel.text = failedSummaryText
        stopTimer()
        invalidateIntrinsicContentSize()
    }
    
    private func setDeniedState() {
        state = .denied
        loadingIndicatorView.stopAnimating()
        loadingIndicatorView.isHidden = true
        exclamationMarkImageView.image = exclamationmarkCircleImage([.systemYellow])
        exclamationMarkImageView.isHidden = false
        indicatorStackView.spacing = 8
        indicatorStackView.alignment = .top
        titleLabel.text = deniedSummaryText
        stopTimer()
        invalidateIntrinsicContentSize()
    }

    private func setSuccessState() {
        state = .success
        loadingIndicatorView.stopAnimating()
        isHidden = true
        stopTimer()
//        invalidateIntrinsicContentSize()
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
