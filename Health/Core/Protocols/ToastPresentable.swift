//
//  Untitled.swift
//  Health
//
//  Created by 하재준 on 7/31/25.
//

import UIKit

@MainActor
protocol ToastPresentable {
    
    /// 화면 하단에 토스트 메시지를 띄웁니다.
    ///
    /// - Parameters:
    ///   - message: 표시할 문자열
    ///   - duration: 토스트가 표시되는 시간 (기본값 2.0초)
    func showToast(message: String, duration: TimeInterval)
}

extension UIViewController: ToastPresentable {}

@MainActor
extension ToastPresentable where Self: UIViewController {
    /// 화면 하단에 캡슐 형태의 토스트 메시지를 띄웁니다.
    /// - Parameters:
    ///   - message: 표시할 문자열
    ///   - duration: 토스트가 완전히 보이는 시간(초) (기본값 2.0초)
    func showToast(message: String, duration: TimeInterval = 2.0) {
        let toastContainer = UIView()
        toastContainer.alpha = 0
        toastContainer.clipsToBounds = true

        let toastLabel = UILabel()
        toastLabel.textAlignment = .center
        toastLabel.font = .systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.numberOfLines = 0

        let isLight = traitCollection.userInterfaceStyle == .light
        let backgroundColor = (isLight ? UIColor.black : UIColor.white).withAlphaComponent(0.7)
        toastContainer.backgroundColor = backgroundColor
        toastLabel.textColor = isLight ? .white : .black

        toastContainer.addSubview(toastLabel)
        view.addSubview(toastContainer)

        toastContainer.translatesAutoresizingMaskIntoConstraints = false
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toastLabel.leadingAnchor.constraint(equalTo: toastContainer.leadingAnchor, constant: 12),
            toastLabel.trailingAnchor.constraint(equalTo: toastContainer.trailingAnchor, constant: -12),
            toastLabel.topAnchor.constraint(equalTo: toastContainer.topAnchor, constant: 8),
            toastLabel.bottomAnchor.constraint(equalTo: toastContainer.bottomAnchor, constant: -8),

            toastContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            toastContainer.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            toastContainer.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])

        view.layoutIfNeeded()
        toastContainer.layer.cornerRadius = toastContainer.bounds.height / 2

        UIView.animate(withDuration: 0.5, animations: {
            toastContainer.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.5,
                           delay: duration,
                           options: .curveEaseOut,
                           animations: { toastContainer.alpha = 0 },
                           completion: { _ in toastContainer.removeFromSuperview() })
        }
    }
}
