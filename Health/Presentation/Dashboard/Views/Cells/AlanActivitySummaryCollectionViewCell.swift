//
//  AlanActivitySummaryCollectionViewCell.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import Combine
import UIKit

final class AlanActivitySummaryCollectionViewCell: CoreCollectionViewCell {

    @IBOutlet weak var summaryLabelView: AISummaryLabel!
    @IBOutlet weak var loadingIndicatorView: AlanLoadingIndicatorView!
    
    private var cancellables: Set<AnyCancellable> = []
    
    private var borderWidth: CGFloat {
        (traitCollection.userInterfaceStyle == .dark) ? 0 : 0.75
    }

    private var viewModel: AlanActivitySummaryCellViewModel!

    override func preferredLayoutAttributesFitting(_ attrs: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        super.preferredLayoutAttributesFitting(attrs)
        
        let newAttrs = attrs.copy() as! UICollectionViewLayoutAttributes

        var contentHeight: CGFloat
        if loadingIndicatorView.state == .success {
            contentHeight = summaryLabelView.intrinsicContentSize.height + 24 // top/bottom 패딩 합
        } else {
            contentHeight = loadingIndicatorView.intrinsicContentSize.height + 24 // top/bottom 패딩 합
        }
        newAttrs.size.height = contentHeight
        return newAttrs

    }

    override func setupAttribute() {
        self.backgroundColor = .boxBg
        self.applyCornerStyle(.medium)
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor.boxBgLightModeStroke.cgColor
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.15
        self.layer.shadowOffset = CGSize(width: 2, height: 2)
        self.layer.shadowRadius = 5
        self.layer.borderWidth = borderWidth

        summaryLabelView.isHidden = true

        registerForTraitChanges()
    }

    private func registerForTraitChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
            self.layer.borderWidth = self.borderWidth
        }
    }
}

extension AlanActivitySummaryCollectionViewCell {

    func bind(with viewModel: AlanActivitySummaryCellViewModel) {
        self.viewModel = viewModel

        viewModel.statePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.render(for: state) }
            .store(in: &cancellables)
    }

    // TODO: - 상태 코드 별로 함수로 나누는 리팩토링하기
    private func render(for state: LoadState<AlanContent>) {
        summaryLabelView.isHidden = true

        switch state {
        case .idle:
            return 

        case .loading:
            loadingIndicatorView.isHidden = false
            loadingIndicatorView.setState(.loading)
            return

        case let .success(content):
            summaryLabelView.isHidden = false
            summaryLabelView.text = content.message
            summaryLabelView.invalidateIntrinsicContentSize()
            loadingIndicatorView.setState(.success)

        case .failure:
            summaryLabelView.isHidden = true
            summaryLabelView.text = nil
            loadingIndicatorView.setState(.failed)
            print("🔴 건강 데이터를 불러오는 데 실패함: AlanActivitySummaryCollectionViewCell")

        case .denied:
            summaryLabelView.isHidden = true
            summaryLabelView.text = nil
            loadingIndicatorView.setState(.denied)
            print("🔵 건강 데이터에 접근할 수 있는 권한이 없음: AlanActivitySummaryCollectionViewCell")
        }
    }
}
