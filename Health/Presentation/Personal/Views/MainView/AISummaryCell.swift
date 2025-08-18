//
//  AISummaryCell.swift
//  Health
//
//  Created by juks86 on 8/10/25.
//

import UIKit
import Combine

class AISummaryCell: CoreCollectionViewCell {

    @IBOutlet weak var aiSummaryLabel: UILabel!
    @IBOutlet weak var summaryBackgroundView: UIView!
    @IBOutlet weak var backgroundHeight: NSLayoutConstraint!

    private var viewModel: AIMonthlySummaryCellViewModel?
    private var cancellables = Set<AnyCancellable>()


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setupAttribute() {
        super.setupAttribute()
        BackgroundHeightUtils.setupShadow(for: self)
        summaryBackgroundView.applyCornerStyle(.medium)
        BackgroundHeightUtils.setupDarkModeBorder(for: summaryBackgroundView)
    }


    override func setupConstraints() {
        super.setupConstraints()
        BackgroundHeightUtils.updateBackgroundHeight(constraint: backgroundHeight, in: self)

        registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (self: Self, _) in
            BackgroundHeightUtils.updateBackgroundHeight(constraint: self.backgroundHeight, in: self)
        }
    }

    // MARK: - Configuration

        /// 셀을 뷰모델과 바인딩
        /// - Parameters:
        ///   - viewModel: 월간 요약 셀 뷰모델
        ///   - promptBuilderService: 프롬프트 빌더 서비스
    func configure(
        with viewModel: AIMonthlySummaryCellViewModel,
        promptBuilderService: any PromptBuilderService
    ) {
        self.viewModel = viewModel
        cancellables.removeAll()

        // 오늘 이미 로딩했다면 아예 로딩하지 않음
        let today = Calendar.current.startOfDay(for: Date())
        let lastLoadDate = UserDefaults.standard.object(forKey: "AISummaryLastLoadDate") as? Date

        if let lastDate = lastLoadDate,
           Calendar.current.isDate(lastDate, inSameDayAs: today),
           let cachedMessage = UserDefaults.standard.string(forKey: "AISummaryCachedMessage") {

            // 캐시된 메시지 바로 표시하고 끝
            aiSummaryLabel.text = cachedMessage
            return
        }

        viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateUI(with: state)
            }
            .store(in: &cancellables)

        Task {
            await viewModel.loadMonthlySummary()
            // 성공하면 캐시에 저장
            if case .loaded(let content) = viewModel.stateSubject.value {
                UserDefaults.standard.set(today, forKey: "AISummaryLastLoadDate")
                UserDefaults.standard.set(content.message, forKey: "AISummaryCachedMessage")
            }
        }
    }

        /// 상태에 따른 UI 업데이트
        /// - Parameter state: 로딩 상태
        private func updateUI(with state: AIMonthlySummaryCellViewModel.LoadState<AIMonthlySummaryCellViewModel.Content>) {
            switch state {
            case .idle:
                // 대기 상태
                aiSummaryLabel.text = "월간 요약 준비 중..."

            case .loading:
                // 로딩 중
                aiSummaryLabel.text = "AI가 월간 활동을 분석하고 있어요..."

            case .loaded(let content):
                // 성공: AI 요약 메시지 표시
                aiSummaryLabel.text = content.message

            case .failed(let error):
                // 실패: 에러 메시지 표시
                aiSummaryLabel.text = "요약을 불러올 수 없어요.\n\(error.localizedDescription)"
            }
        }

        // MARK: - Cleanup

        override func prepareForReuse() {
            super.prepareForReuse()

            // 구독 해제
            cancellables.removeAll()

            // 뷰모델 해제
            viewModel = nil

            // 라벨 초기화
            aiSummaryLabel.text = "월간 요약을 불러오는 중..."
        }
}
