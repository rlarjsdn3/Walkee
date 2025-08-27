//
//  DailyAvtivitySummaryCollectionViewCell.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import Combine
import HealthKit
import UIKit
import SwiftUI

final class HealthInfoStackCollectionViewCell: CoreCollectionViewCell {

    @IBOutlet weak var symbolContainerView: UIView!
    @IBOutlet weak var symbolImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var chartsContainerView: UIView!
    @IBOutlet weak var permissionDeniedView: PermissionDeniedCompactView!

    private var cancellable: Set<AnyCancellable> = []
    private var chartsHostingController: UIHostingController<LineChartsView>?

    @IBOutlet weak var symbolImageHeightConstraint: NSLayoutConstraint!

    private var borderWidth: CGFloat {
        (traitCollection.userInterfaceStyle == .dark) ? 0 : 0.75
    }
    
    private var viewModel: HealthInfoStackCellViewModel!

    override func layoutSubviews() {
        super.layoutSubviews()

        sizeClasses(vRhR: {
            self.titleLabel.font = .preferredFont(forTextStyle: .caption2)
            self.symbolImageHeightConstraint = self.symbolImageHeightConstraint.setMultiplier(multiplier: 0.4)
        })
        symbolContainerView.layer.cornerRadius = symbolContainerView.bounds.width / 2
    }

    override func prepareForReuse() {
        cancellable.removeAll()
        chartsContainerView.subviews.forEach { $0.removeFromSuperview() }
        chartsHostingController?.removeFromParent()
        chartsHostingController = nil
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

        symbolContainerView.backgroundColor = .systemGray5

        valueLabel.minimumScaleFactor = 0.5
        valueLabel.adjustsFontSizeToFitWidth = true

        chartsContainerView.backgroundColor = .boxBg
        chartsContainerView.isHidden = (traitCollection.horizontalSizeClass == .compact)

        permissionDeniedView.isHidden = true
        permissionDeniedView.symbomPointSize = 8

        registerForTraitChanges()
    }

    private func registerForTraitChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
            self.layer.borderWidth = self.borderWidth
        }
    }
}

extension HealthInfoStackCollectionViewCell {

    func bind(
        with viewModel: HealthInfoStackCellViewModel,
        parent: UIViewController?
    ) {
        self.viewModel = viewModel

        viewModel.statePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.render(state, parent: parent) }
            .store(in: &cancellable)
    }

    // TODO: - 상태 코드 별로 함수로 나누는 리팩토링하기
    private func render(_ new: LoadState<InfoStackContent>, parent: UIViewController?) {
        titleLabel.text = viewModel.itemID.kind.title
        unitLabel.text = viewModel.itemID.kind.unitString
        symbolImageView.image = UIImage(systemName: viewModel.itemID.kind.systemName)
        chartsContainerView.isHidden = true
        permissionDeniedView.isHidden = true

        let valueText: String

        switch new {
        case let .success(content):
            valueText = formatValue(kind: viewModel.itemID.kind, value: content.value)

            if let charts = content.charts, !charts.isEmpty {
                sizeClasses(vRhR: {
                    self.addChartsHostingController(with: charts, parent: parent)
                })
            }

        case .failure:
            valueText = "0"
            print("🔴 건강 데이터를 불러오는 데 실패함: HealthInfoStackCell (\(viewModel.itemID.kind.quantityTypeIdentifier))")

        case .denied:
            valueText = "-"
            permissionDeniedView.isHidden = false
            print("🔵 건강 데이터에 접근할 수 있는 권한이 없음: HealthInfoStackCell (\(viewModel.itemID.kind.quantityTypeIdentifier))")

        default:
            return
        }

        valueLabel.text = valueText
    }

    private func formatValue(kind: DashboardStackKind, value: Double) -> String {
        if value < 0.1 {
            return "0"
        } else {
            switch kind {
            case .appleExerciseTime:
                return String(format: "%.0f", value)
            default:
                return String(format: "%.1f", value)
            }

        }
    }

    private func addChartsHostingController(
        with charts: [InfoStackContent.Charts],
        parent: UIViewController?
    ) {
        // 가장 최근 데이터를 오른쪽에 정렬시키기
        let reversed = Array(charts.reversed())
        let suffixed = reversed.suffix(7)
        let hkd = suffixed.map { HKData(startDate: $0.date, endDate: $0.date, value: $0.value) }
        let hVC = LineChartsHostingController(chartsData: hkd)
        parent?.addChild(hVC, to: chartsContainerView)
        self.chartsHostingController = hVC
        chartsContainerView.isHidden = false
    }
}
