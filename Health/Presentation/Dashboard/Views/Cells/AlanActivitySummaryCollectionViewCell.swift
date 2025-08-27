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
    
    @MainActor required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func preferredLayoutAttributesFitting(_ attrs: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        super.preferredLayoutAttributesFitting(attrs)

        summaryLabelView.layoutIfNeeded()
        loadingIndicatorView.layoutIfNeeded()

        let topBottomPadding: CGFloat = 24 // top·bottom 패딩 합
        let newAttrs = attrs.copy() as! UICollectionViewLayoutAttributes

        var contentHeight: CGFloat
        switch viewModel.loadState {
        case let .success(content):
            summaryLabelView.text = content.message
            contentHeight = summaryLabelView.getCGSize(content.message).height + topBottomPadding

        case .failure:
            loadingIndicatorView.setState(.failed)
            contentHeight = loadingIndicatorView.getCGSize(.failed).height + topBottomPadding

        case .denied:
            loadingIndicatorView.setState(.denied)
            contentHeight = loadingIndicatorView.getCGSize(.denied).height + topBottomPadding

        default:
            loadingIndicatorView.setState(.loading)
            contentHeight = loadingIndicatorView.getCGSize(.loading).height + topBottomPadding
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
        self.layer.shadowOpacity = 0.05
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

    private func render(for state: LoadState<AlanContent>) {

        switch state {
        case .loading:
            summaryLabelView.isHidden = true
            loadingIndicatorView.isHidden = false
            loadingIndicatorView.setState(.loading)

        case let .success(content):
            summaryLabelView.isHidden = false
            summaryLabelView.text = content.message
            loadingIndicatorView.setState(.success)

        case .failure:
            summaryLabelView.text = nil
            summaryLabelView.isHidden = true
            loadingIndicatorView.setState(.failed)
            print("🔴 건강 데이터를 불러오는 데 실패함: AlanActivitySummaryCollectionViewCell")

        case .denied:
            summaryLabelView.text = nil
            summaryLabelView.isHidden = true
            loadingIndicatorView.setState(.denied)
            print("🔵 건강 데이터에 접근할 수 있는 권한이 없음: AlanActivitySummaryCollectionViewCell")

        default:
            return
        }
    }
}
