//
//  HealthInfoCardCollectionViewCell.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import Combine
import UIKit

final class HealthInfoCardCollectionViewCell: CoreCollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var statusContainerView: UIView!
    @IBOutlet weak var gaitStatusLabel: UILabel!
    @IBOutlet weak var statusProgressBarView: StatusProgressBarView!
    
    private var viewModel: HealthInfoCardCellViewModel!

    private var cancellable: Set<AnyCancellable> = []
    
    private var percentageFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .percent
        return nf
    }()

    override func prepareForReuse() {
        cancellable.removeAll()
    }
    
    override func setupAttribute() {
//       self.applyCornerStyle(.medium)
        self.backgroundColor = .boxBg
        self.layer.cornerRadius = 12 // medium
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor.separator.cgColor
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.05
        self.layer.shadowOffset = CGSize(width: 2, height: 2)
        self.layer.shadowRadius = 5
        self.layer.borderWidth = (traitCollection.userInterfaceStyle == .dark) ? 0 : 1

        statusContainerView.applyCornerStyle(.small)

        registerForTraitChanges()
    }

    private func registerForTraitChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
            if self.traitCollection.userInterfaceStyle == .dark {
                self.layer.borderWidth = 0
            } else {
                self.layer.borderWidth = 1
            }
        }
    }
}

extension HealthInfoCardCollectionViewCell {
    
    func bind(with viewModel: HealthInfoCardCellViewModel) {
        self.viewModel = viewModel
        
        viewModel.statePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in  self?.render(for: state) }
            .store(in: &cancellable)
    }
    
    private func render(for state: HKLoadState) {
        var attrString: NSAttributedString
        let unitString = viewModel.itemID.kind.unitString
        
        titleLabel.text = viewModel.itemID.kind.title
        statusProgressBarView.higherIsBetter = viewModel.itemID.kind.higherIsBetter
        statusProgressBarView.thresholdsValues = viewModel.itemID.kind.thresholdValues(age: viewModel.anchorAge)
        
        switch state {
        case .idle:
            return // TODO: - 플레이스 홀더 UI 구성하기
            
        case .loading:
            return // TODO: - 스켈레톤 UI 구성하기
            
        case let .success(data, _):
            let status = viewModel.evaluateGaitStatus(data.value)
    
            statusProgressBarView.currentValue = data.value
            statusProgressBarView.numberFormatter = {
                switch viewModel.itemID.kind {
                case .walkingSpeed, .walkingStepLength:                            return nil
                case .walkingAsymmetryPercentage, .walkingDoubleSupportPercentage: return percentageFormatter
                }
            }()
            
            let hkValue = {
                switch viewModel.itemID.kind {
                case .walkingSpeed, .walkingStepLength:                            return data.value
                case .walkingAsymmetryPercentage, .walkingDoubleSupportPercentage: return data.value * 100.0
                }
            }()
            
            attrString = NSAttributedString(string: String(format: "%.1f", hkValue) + unitString)
                .font(.preferredFont(forTextStyle: .footnote), to: unitString)
                .foregroundColor(.secondaryLabel, to: unitString)
            
            gaitStatusLabel.text = status.rawValue
            gaitStatusLabel.textColor = status.backgroundColor
            statusContainerView.backgroundColor = status.secondaryBackgroundColor
            
        case .failure:
            attrString = NSAttributedString(string: "- " + unitString)
                .font(.preferredFont(forTextStyle: .footnote), to: unitString)
                .foregroundColor(.secondaryLabel, to: unitString)
            statusContainerView.isHidden = true
            statusProgressBarView.currentValue = nil
            
            print("🔴 Failed to fetch HealthKit data: HealthInfoCardCollectionViewCell (\(viewModel.itemID.kind.quantityTypeIdentifier))")
        }
        
        valueLabel.attributedText = attrString
    }
}
