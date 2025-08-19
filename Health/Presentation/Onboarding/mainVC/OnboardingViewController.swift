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

    override func initVM() {}

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
        descriptionLabel.text = "사용자에게 더 정확한 운동측정과 맞춤 추천을 제공하기 위해 사용자 입력 정보가 필요합니다."
        descriptionLabel.numberOfLines = 0
        descriptionLabel.alpha = 0.7

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
                iPadWidthConstraint = continueButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7)
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

