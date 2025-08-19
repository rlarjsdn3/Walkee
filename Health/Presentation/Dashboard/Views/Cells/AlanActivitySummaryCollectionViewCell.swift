//
//  AlanActivitySummaryCollectionViewCell.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import Combine
import UIKit

final class AlanActivitySummaryCollectionViewCell: CoreCollectionViewCell {

    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var chatBotImageView: UIImageView!
    @IBOutlet weak var loadingIndicatorView: AlanLoadingIndicatorView!
    
    private var cancellables: Set<AnyCancellable> = []
    
    private var borderWidth: CGFloat {
        (traitCollection.userInterfaceStyle == .dark) ? 0 : 0.75
    }

    private var viewModel: AlanActivitySummaryCellViewModel!

    // TODO: - ChatBotImageView / SummaryLabel을 별도 뷰로 빼기
    override func preferredLayoutAttributesFitting(_ attrs: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()

        let target = CGSize(
            width: attrs.size.width,
            height: UIView.layoutFittingCompressedSize.height
        )
        let size = self.systemLayoutSizeFitting(
            target,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        attrs.size = size

        // TODO: - 아래 코드를 사용하지 않고도 Intrinsic Content Size로 셀의 높이 결정하기
        if loadingIndicatorView.state == .success {
            let text: NSString = (summaryLabel.attributedText?.string as NSString?) ??
                                 (summaryLabel.text as NSString?) ?? ""
            let font: UIFont = summaryLabel.font ?? UIFont.preferredFont(forTextStyle: .callout)
            let width = max(0, self.bounds.width
                            - 24    // leading/trailing 패딩 합
                            - 26)   //  좌측 아이콘의 고정 너비


            let rect = text.boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesFontLeading, .usesLineFragmentOrigin],
                attributes: [.font: font],
                context: nil
            )
            attrs.size.height = rect.height + 24 // top/bottom 패딩 합
        }

        return attrs

    }

    override func setupAttribute() {
        self.backgroundColor = .boxBg
        self.applyCornerStyle(.medium)
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor.separator.cgColor
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.15
        self.layer.shadowOffset = CGSize(width: 2, height: 2)
        self.layer.shadowRadius = 5
        self.layer.borderWidth = borderWidth

        summaryLabel.isHidden = true
        chatBotImageView.isHidden = true

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
        summaryLabel.isHidden = true
        chatBotImageView.isHidden = true

        switch state {
        case .idle:
            return 

        case .loading:
            loadingIndicatorView.isHidden = false
            loadingIndicatorView.setState(.loading)
            return

        case let .success(content):
            chatBotImageView.isHidden = false
            summaryLabel.isHidden = false
            summaryLabel.text = content.message
            loadingIndicatorView.setState(.success)

        case .failure:
            summaryLabel.text = nil
            summaryLabel.isHidden = true
            chatBotImageView.isHidden = true
            loadingIndicatorView.setState(.failed)
            print("🔴 건강 데이터를 불러오는 데 실패함: AlanActivitySummaryCollectionViewCell")

        case .denied:
            summaryLabel.text = nil
            summaryLabel.isHidden = true
            chatBotImageView.isHidden = true
            loadingIndicatorView.setState(.denied)
            print("🔵 건강 데이터에 접근할 수 있는 권한이 없음: AlanActivitySummaryCollectionViewCell")
        }
    }
}
