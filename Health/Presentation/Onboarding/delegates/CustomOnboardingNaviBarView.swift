//
//  CustomNavigationBarViewDelegate.swift
//  Health
//
//  Created by 권도현 on 8/13/25.
//


import UIKit

protocol CustomNavigationBarViewDelegate: AnyObject {
    func backButtonTapped()
}

class CustomNavigationBarView: UIView {
    
    weak var delegate: CustomNavigationBarViewDelegate?
    
    private(set) var progressIndicatorStackView: ProgressIndicatorStackView
    
    let backButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "chevron.left")
        button.setImage(image, for: .normal)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    init(totalPages: Int) {
        self.progressIndicatorStackView = ProgressIndicatorStackView(totalPages: totalPages)
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        backButton.addTarget(self, action: #selector(backButtonAction), for: .touchUpInside)
    }
    
    @objc private func backButtonAction() {
        delegate?.backButtonTapped()
    }
    
    private func setupViews() {
        addSubview(backButton)
        addSubview(progressIndicatorStackView)
        progressIndicatorStackView.translatesAutoresizingMaskIntoConstraints = false
        
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            progressIndicatorStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressIndicatorStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressIndicatorStackView.heightAnchor.constraint(equalToConstant: 4),
            progressIndicatorStackView.widthAnchor.constraint(equalToConstant: 320),
        ])
    }

    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
