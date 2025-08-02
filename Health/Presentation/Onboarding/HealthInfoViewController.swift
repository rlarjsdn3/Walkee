//
//  HealthInfoViewController.swift
//  Health
//
//  Created by 권도현 on 8/1/25.
//

import UIKit

class HealthInfoViewController: CoreViewController {

    private let pageIndicatorStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        return stack
    }()

    override func initVM() {
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }

    
    override func setupHierarchy() {
        [pageIndicatorStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }

    override func setupAttribute() {
        setupPageIndicators(currentPage: 1)
    }
    
    override func setupConstraints() {
        NSLayoutConstraint.activate([
            pageIndicatorStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -20),
            pageIndicatorStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageIndicatorStack.heightAnchor.constraint(equalToConstant: 4),
            pageIndicatorStack.widthAnchor.constraint(equalToConstant: 320)
        ])
    }

    private func setupPageIndicators(currentPage: Int) {
        pageIndicatorStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for i in 0..<4 {
            let bar = UIView()
            bar.backgroundColor = (i <= currentPage) ? .cyan : .darkGray
            bar.layer.cornerRadius = 2
            pageIndicatorStack.addArrangedSubview(bar)
        }
    }
}
