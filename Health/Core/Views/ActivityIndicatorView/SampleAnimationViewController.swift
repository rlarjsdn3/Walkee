//
//  SampleAnimationViewController.swift
//  Health
//
//  Created by Seohyun Kim on 8/10/25.
//

import UIKit


// MARK: Custom Activity Indicator 적용하는 SampleViewController
class SampleAnimationViewController: UIViewController {
	
	private let indicator = CustomActivityIndicatorView()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = .systemBackground
		
		setupIndicator()
		indicator.startAnimating()
	}
	
	private func setupIndicator() {
		indicator.color = .accent
		indicator.dotDiameter = 50
		indicator.translatesAutoresizingMaskIntoConstraints = false
		
		view.addSubview(indicator)
		NSLayoutConstraint.activate([
			indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
			indicator.widthAnchor.constraint(equalToConstant: 60),
			indicator.heightAnchor.constraint(equalToConstant: 60)
		])
	}
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

#Preview {
	SampleAnimationViewController()
}
#endif
