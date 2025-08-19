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
    @IBOutlet weak var permissionDeniedView: PermissionDeniedFullView!

    private var viewModel: HealthInfoCardCellViewModel!

    private var cancellable: Set<AnyCancellable> = []
    
    private var borderWidth: CGFloat {
        (traitCollection.userInterfaceStyle == .dark) ? 0 : 0.75
    }
    
    private var percentageFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .percent
        return nf
    }()

    override func prepareForReuse() {
        cancellable.removeAll()
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

        statusContainerView.isHidden = true
        statusContainerView.applyCornerStyle(.small)

        permissionDeniedView.isHidden = true
        permissionDeniedView.applyCornerStyle(.medium)

        registerForTraitChanges()
    }

    private func registerForTraitChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
            self.layer.borderWidth = self.borderWidth
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

    // TODO: - 상태 코드 별로 함수로 나누는 리팩토링하기
    private func render(for state: LoadState<InfoCardContent>) {
        var attrString: NSAttributedString
        let unitString = viewModel.itemID.kind.unitString
        
        titleLabel.text = viewModel.itemID.kind.title
        statusProgressBarView.higherIsBetter = viewModel.itemID.kind.higherIsBetter
        statusProgressBarView.thresholdsValues = viewModel.itemID.kind.thresholdValues(age: viewModel.anchorAge)
        statusContainerView.isHidden = true
        permissionDeniedView.isHidden = true

        switch state {
        case .idle:
            return
            
        case .loading:
            return
            
        case let .success(content):
            let status = viewModel.evaluateGaitStatus(content.value)
            statusProgressBarView.currentValue = content.value
            statusProgressBarView.numberFormatter = {
                switch viewModel.itemID.kind {
                case .walkingSpeed, .walkingStepLength:
                    return nil
                case .walkingAsymmetryPercentage, .walkingDoubleSupportPercentage:
                    return percentageFormatter
                }
            }()
            
            let hkValue = {
                switch viewModel.itemID.kind {
                case .walkingSpeed, .walkingStepLength:
                    return content.value
                case .walkingAsymmetryPercentage, .walkingDoubleSupportPercentage:
                    return content.value * 100.0
                }
            }()
            
            attrString = NSAttributedString(string: String(format: "%.1f", hkValue) + unitString)
            gaitStatusLabel.text = status.rawValue
            gaitStatusLabel.textColor = status.backgroundColor
            statusContainerView.isHidden = false
            statusContainerView.backgroundColor = status.secondaryBackgroundColor
            
        case .failure:
            attrString = NSAttributedString(string: "- " + unitString)
            statusContainerView.isHidden = true
            statusProgressBarView.currentValue = nil
            print("🔴 건강 데이터를 불러오는 데 실패함: HealthInfoCardCollectionViewCell (\(viewModel.itemID.kind.quantityTypeIdentifier))")

        case .denied:
            attrString = NSAttributedString(string: "- " + unitString)
            statusContainerView.isHidden = true
            statusProgressBarView.currentValue = nil
            permissionDeniedView.isHidden = false
            print("🔵 건강 데이터에 접근할 수 있는 권한이 없음: HealthInfoCardCell (\(viewModel.itemID.kind.quantityTypeIdentifier))")
        }
        
        valueLabel.attributedText = attrString
            .font(.preferredFont(forTextStyle: .footnote), to: unitString)
            .foregroundColor(.secondaryLabel, to: unitString)
    }
}
