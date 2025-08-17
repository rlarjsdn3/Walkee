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
    @IBOutlet weak var loadingIndicatorView: AlanLoadingIndicatorView!
    
    private var cancellables: Set<AnyCancellable> = []
    
    private var borderWidth: CGFloat {
        (traitCollection.userInterfaceStyle == .dark) ? 0 : 0.75
    }

    private var viewModel: AlanActivitySummaryCellViewModel!

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
        summaryLabel.text = ""
        
        switch state {
        case .idle:
            return // TODO: - 플레이스 홀더 UI 구성하기

        case .loading:
            loadingIndicatorView.setState(.loading)
            return

        case let .success(content):
            summaryLabel.text = content.message
            loadingIndicatorView.setState(.success)

        case .failure:
            summaryLabel.text = nil
            loadingIndicatorView.setState(.failed)
            print("🔴 건강 데이터를 불러오는 데 실패함: AlanActivitySummaryCollectionViewCell")

        case .denied:
            summaryLabel.text = nil
            loadingIndicatorView.setState(.denied)
            print("🔵 건강 데이터에 접근할 수 있는 권한이 없음: AlanActivitySummaryCollectionViewCell")
        }
    }
}
