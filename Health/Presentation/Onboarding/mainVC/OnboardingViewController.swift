//
//  OnboardingViewController.swift
//  Health
//
//  Created by 권도현 on 8/1/25.
//

import UIKit

class OnboardingViewController: CoreGradientViewController {

    @IBOutlet weak var appImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var continueButtonLeading: NSLayoutConstraint!
    @IBOutlet weak var continueButtonTrailing: NSLayoutConstraint!

    private var iPadWidthConstraint: NSLayoutConstraint?
    private var iPadCenterXConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyBackgroundGradient(.midnightBlack)

        continueButton.applyCornerStyle(.medium)
        continueButton.isEnabled = true
        continueButton.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)

        appImageView.image = UIImage(named: "appIconAny")
        appImageView.contentMode = .scaleAspectFit
        appImageView.applyCornerStyle(.medium)
        appImageView.clipsToBounds = true

        titleLabel.text = "환영합니다!"

        let descriptionText = """
Apple 건강앱과 연동해 신체 정보와 성별을 기반으로 맞춤형 건강 관리를 제공합니다. 달력에서 일별 걸음 목표 달성률을 확인하고 걸음 패턴을 분석합니다. 개인에게 맞는 난이도의 추천 걷기 코스를 얻을 수 있고 챗봇을 통해 다양한 걷기 정보를 얻을 수 있습니다.
"""
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .center

        let attributedString = NSAttributedString(
            string: descriptionText,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.white.withAlphaComponent(0.7),
            ]
        )
        descriptionLabel.attributedText = attributedString

        if let parentVC = parent as? ProgressContainerViewController {
            parentVC.customNavigationBar.backButton.isHidden = true
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let isIpad = traitCollection.horizontalSizeClass == .regular &&
                     traitCollection.verticalSizeClass == .regular

        if isIpad {
            continueButtonLeading?.isActive = false
            continueButtonTrailing?.isActive = false

            if iPadWidthConstraint == nil {
                iPadWidthConstraint = continueButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6)
                iPadCenterXConstraint = continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
                iPadWidthConstraint?.isActive = true
                iPadCenterXConstraint?.isActive = true
            }
        } else {
            iPadWidthConstraint?.isActive = false
            iPadCenterXConstraint?.isActive = false

            continueButtonLeading?.isActive = true
            continueButtonTrailing?.isActive = true
        }
    }

    @IBAction func buttonAction(_ sender: Any) {
        performSegue(withIdentifier: "goToHealthLink", sender: self)
    }
}
