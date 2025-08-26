//
//  AISummaryCell.swift
//  Health
//
//  Created by juks86 on 8/10/25.
//

import UIKit
import Combine

class AISummaryCell: CoreCollectionViewCell {

    @IBOutlet weak var chatbotView: UIImageView!
    @IBOutlet weak var aiSummaryLabel: UILabel!
    @IBOutlet weak var summaryBackgroundView: UIView!
    @IBOutlet weak var backgroundHeight: NSLayoutConstraint!
    
    private let loadingIndicatorView = AlanLoadingIndicatorView()
    private var viewModel: AIMonthlySummaryCellViewModel?
    private var cancellables = Set<AnyCancellable>()

    override func awakeFromNib() {
        super.awakeFromNib()
        Task { @MainActor in
            setupLoadingIndicator()
        }
    }
    
    override func setupAttribute() {
        super.setupAttribute()
        BackgroundHeightUtils.setupShadow(for: self)
        summaryBackgroundView.applyCornerStyle(.medium)
        BackgroundHeightUtils.setupDarkModeBorder(for: summaryBackgroundView)
    }

    private func setupLoadingIndicator() {
        summaryBackgroundView.addSubview(loadingIndicatorView)
        loadingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loadingIndicatorView.centerXAnchor.constraint(equalTo: summaryBackgroundView.centerXAnchor, constant: 0),
            loadingIndicatorView.centerYAnchor.constraint(equalTo: summaryBackgroundView.centerYAnchor, constant: 0),
            loadingIndicatorView.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
//            loadingIndicatorView.widthAnchor.constraint(equalToConstant: 300),
//            loadingIndicatorView.heightAnchor.constraint(equalToConstant: 70)
            loadingIndicatorView.leadingAnchor.constraint(greaterThanOrEqualTo: summaryBackgroundView.leadingAnchor, constant: 16),
            loadingIndicatorView.trailingAnchor.constraint(lessThanOrEqualTo: summaryBackgroundView.trailingAnchor, constant: -16)
        ])
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        BackgroundHeightUtils.updateBackgroundHeight(constraint: backgroundHeight, in: self)
        
        registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (self: Self, _) in
            BackgroundHeightUtils.updateBackgroundHeight(constraint: self.backgroundHeight, in: self)
        }
    }
    
    // MARK: - Configuration
    
    func configure(
        with viewModel: AIMonthlySummaryCellViewModel,
        promptBuilderService: any PromptBuilderService
    ) {
        self.viewModel = viewModel
        cancellables.removeAll()
        render(for: .loading)
        
        // 상태 변화 구독
        viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.render(for: state)
            }
            .store(in: &cancellables)
        
        // 월간 요약 로딩 시작
        Task {
            await viewModel.loadMonthlySummary()
        }
    }
    
    // MARK: - State Handling
    
    private func render(for state: LoadState<AIMonthlySummaryCellViewModel.Content>) {
        
        switch state {
        case .idle:
            aiSummaryLabel.isHidden = true
            loadingIndicatorView.isHidden = false
            loadingIndicatorView.setState(.loading)
            chatbotView.isHidden = true

        case .loading:
            aiSummaryLabel.isHidden = true
            loadingIndicatorView.isHidden = false
            loadingIndicatorView.setState(.loading)
            chatbotView.isHidden = true

        case .success(let content):
            loadingIndicatorView.setState(.success)
            aiSummaryLabel.isHidden = false
            aiSummaryLabel.text = content.message
            chatbotView.isHidden = false

        case .failure(let error):
            aiSummaryLabel.isHidden = true
            loadingIndicatorView.isHidden = false
            loadingIndicatorView.setState(.failed)
            loadingIndicatorView.frame.size.height = loadingIndicatorView.getCGSize(.failed).height
            chatbotView.isHidden = true

        case .denied:
            aiSummaryLabel.isHidden = true
            aiSummaryLabel.text = nil
            loadingIndicatorView.isHidden = false
            loadingIndicatorView.setState(.denied)
            loadingIndicatorView.frame.size.height = loadingIndicatorView.getCGSize(.denied).height
            chatbotView.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cancellables.removeAll()
        viewModel = nil
        
        // 초기 상태로 리셋
        aiSummaryLabel.isHidden = true
        loadingIndicatorView.setState(.loading)
    }
}
