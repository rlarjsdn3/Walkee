//
//  AISummaryCell.swift
//  Health
//
//  Created by juks86 on 8/10/25.
//

import UIKit
import Combine

class AISummaryCell: CoreCollectionViewCell {

    @IBOutlet weak var summaryBackgroundView: UIView!
    @IBOutlet weak var backgroundHeight: NSLayoutConstraint!
    
    private let loadingIndicatorView = AlanLoadingIndicatorView()
    private var viewModel: AIMonthlySummaryCellViewModel?
    private var cancellables = Set<AnyCancellable>()
    private let aiSummaryLabel = AISummaryLabel()

    override func awakeFromNib() {
        super.awakeFromNib()
        setupAISummaryLabel()
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

    private func setupAISummaryLabel() {
        summaryBackgroundView.addSubview(aiSummaryLabel)
        aiSummaryLabel.translatesAutoresizingMaskIntoConstraints = false
        aiSummaryLabel.isHidden = true

        NSLayoutConstraint.activate([
            aiSummaryLabel.topAnchor.constraint(equalTo: summaryBackgroundView.topAnchor, constant: 16),
            aiSummaryLabel.leadingAnchor.constraint(equalTo: summaryBackgroundView.leadingAnchor, constant: 16),
            aiSummaryLabel.trailingAnchor.constraint(equalTo: summaryBackgroundView.trailingAnchor, constant: -16),
            aiSummaryLabel.bottomAnchor.constraint(equalTo: summaryBackgroundView.bottomAnchor, constant: -16)
        ])
    }

    private func setupLoadingIndicator() {
        summaryBackgroundView.addSubview(loadingIndicatorView)
        loadingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loadingIndicatorView.centerXAnchor.constraint(equalTo: summaryBackgroundView.centerXAnchor),
            loadingIndicatorView.centerYAnchor.constraint(equalTo: summaryBackgroundView.centerYAnchor),
            loadingIndicatorView.leadingAnchor.constraint(greaterThanOrEqualTo: summaryBackgroundView.leadingAnchor, constant: 0),
            loadingIndicatorView.trailingAnchor.constraint(lessThanOrEqualTo: summaryBackgroundView.trailingAnchor, constant: 0)
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
            
        case .loading:
            aiSummaryLabel.isHidden = true
            loadingIndicatorView.isHidden = false
            loadingIndicatorView.setState(.loading)
            
        case .success(let content):
            loadingIndicatorView.setState(.success) // 이게 인디케이터를 숨김
            aiSummaryLabel.isHidden = false
            aiSummaryLabel.text = content.message
            
        case .failure(let error):
            aiSummaryLabel.isHidden = true
            loadingIndicatorView.isHidden = false
            loadingIndicatorView.setState(.failed)
            
        case .denied:
            aiSummaryLabel.isHidden = true
            aiSummaryLabel.text = nil
            loadingIndicatorView.isHidden = false
            loadingIndicatorView.setState(.denied)
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
