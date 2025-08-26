//
//  Untitled.swift
//  Health
//
//  Created by 하재준 on 7/31/25.
//

import UIKit

@MainActor
protocol Toastable {
    
    /// 화면 하단에 토스트 메시지를 띄웁니다.
    ///
    /// - Parameters:
    ///   - message: 표시할 문자열
    ///   - duration: 토스트가 표시되는 시간 (기본값 2.0초)
    func showToast(message: String, duration: TimeInterval)
}

extension UIViewController: Toastable {}

@MainActor
extension Toastable where Self: UIViewController {
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
		let backgroundColor = (isLight ? UIColor.black : UIColor.white).withAlphaComponent(0.9)
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
			UIView.animate(
				withDuration: 0.5,
				delay: duration,
				options: .curveEaseOut,
				animations: { toastContainer.alpha = 0 },
				completion: { _ in toastContainer.removeFromSuperview() }
			)
		}
	}
	
	func showWarningToast(title: String, message: String, duration: TimeInterval = 2.0) {
		let toastContainer = UIView()
		toastContainer.alpha = 0
		toastContainer.clipsToBounds = true
		toastContainer.layer.cornerRadius = 12
		
		toastContainer.backgroundColor = .toastWarningBg
		
		let iconView = UIImageView()
		let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
		iconView.image = UIImage(systemName: "exclamationmark.triangle.fill", withConfiguration: config)
		iconView.tintColor = .warningSymbol
		
		let titleLabel = UILabel()
		titleLabel.text = title
		titleLabel.font = .boldSystemFont(ofSize: 16)
		titleLabel.textColor = .label
		titleLabel.numberOfLines = 0
		
		let messageLabel = UILabel()
		messageLabel.text = message
		messageLabel.font = .systemFont(ofSize: 14)
		messageLabel.textColor = .secondaryLabel
		messageLabel.numberOfLines = 0
		
		let textStack = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
		textStack.axis = .vertical
		textStack.spacing = 4
		
		let contentStack = UIStackView(arrangedSubviews: [iconView, textStack])
		contentStack.axis = .horizontal
		contentStack.alignment = .center
		contentStack.spacing = 8
		
		toastContainer.addSubview(contentStack)
		view.addSubview(toastContainer)
		
		toastContainer.translatesAutoresizingMaskIntoConstraints = false
		contentStack.translatesAutoresizingMaskIntoConstraints = false
		
		NSLayoutConstraint.activate([
			contentStack.leadingAnchor.constraint(equalTo: toastContainer.leadingAnchor, constant: 12),
			contentStack.trailingAnchor.constraint(equalTo: toastContainer.trailingAnchor, constant: -12),
			contentStack.topAnchor.constraint(equalTo: toastContainer.topAnchor, constant: 12),
			contentStack.bottomAnchor.constraint(equalTo: toastContainer.bottomAnchor, constant: -12),
			
			toastContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			toastContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
			toastContainer.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
			toastContainer.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
		])
		
		UIView.animate(withDuration: 0.5, animations: {
			toastContainer.alpha = 1
		}) { _ in
			UIView.animate(
				withDuration: 0.5,
				delay: duration,
				options: .curveEaseOut,
				animations: { toastContainer.alpha = 0 },
				completion: { _ in toastContainer.removeFromSuperview() }
			)
		}
	}
	
	func showToastAboveKeyboard(
		type: ToastType,
		title: String,
		message: String,
		duration: TimeInterval = 2.0,
		keyboardHeight: CGFloat = 0
	) {
		guard let keyWindow = getKeyWindow() else { return }

		let toastView = buildToastView(type: type, title: title, message: message)
		keyWindow.addSubview(toastView)
		toastView.translatesAutoresizingMaskIntoConstraints = false

		let constraints = makePlatformToastConstraints(
			for: toastView,
			in: keyWindow,
			keyboardHeight: keyboardHeight
		)

		NSLayoutConstraint.activate(constraints)
		animateToast(view: toastView, duration: duration)
	}

	/// 현재 앱의 키 윈도우를 반환
	/// - Returns: keyWindow, 없을 경우 nil
	private func getKeyWindow() -> UIWindow? {
		UIApplication.shared.connectedScenes
			.compactMap { $0 as? UIWindowScene }
			.flatMap { $0.windows }
			.first(where: { $0.isKeyWindow })
	}
	/// 키보드 상태에 따라 토스트의 하단 오프셋 값을 계산
	/// - Parameters:
	///   - window: 기준 윈도우
	///   - keyboardHeight: 현재 키보드 높이
	/// - Returns: 키보드 또는 기본 값에 따른 하단 offset
	private func calculateToastBottomOffset(
		for window: UIWindow,
		keyboardHeight: CGFloat
	) -> CGFloat {
		let safeBottomInset = window.safeAreaInsets.bottom

		// iPad는 키보드가 커서 더 큰 offset 필요
		let defaultOffset: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 200 : 100

		let finalOffset = keyboardHeight > 0
			? (keyboardHeight + 8)
			: (safeBottomInset + defaultOffset)

		return finalOffset
	}
	/// 기본적인 하단 중심 기준의 토스트 제약을 생성
	/// - Parameters:
	///   - toastView: 토스트 뷰
	///   - window: 기준 윈도우
	///   - bottomOffset: 하단 offset
	/// - Returns: NSLayoutConstraint 배열
	private func makeToastConstraints(
		for toastView: UIView,
		in window: UIWindow,
		bottomOffset: CGFloat
	) -> [NSLayoutConstraint] {
		var constraints: [NSLayoutConstraint] = [
			toastView.bottomAnchor.constraint(equalTo: window.bottomAnchor, constant: -bottomOffset)
		]

		constraints += horizontalConstraints(for: toastView, in: window)
		return constraints
	}
	/// 디바이스에 따라 토스트의 수평 제약을 설정
	/// - Parameters:
	///   - toastView: 토스트 뷰
	///   - window: 기준 윈도우
	/// - Returns: NSLayoutConstraint 배열
	private func horizontalConstraints(
		for toastView: UIView,
		in window: UIWindow
	) -> [NSLayoutConstraint] {
		if UIDevice.current.userInterfaceIdiom == .pad {
			return [
				toastView.centerXAnchor.constraint(equalTo: window.centerXAnchor),
				toastView.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
				toastView.leadingAnchor.constraint(greaterThanOrEqualTo: window.leadingAnchor, constant: 16),
				toastView.trailingAnchor.constraint(lessThanOrEqualTo: window.trailingAnchor, constant: -16)
			]
		} else {
			return [
				toastView.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 16),
				toastView.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -16)
			]
		}
	}
	/// 플랫폼(디바이스) 특성을 고려하여 토스트의 위치 제약을 생성
	/// - Parameters:
	///   - toastView: 토스트 뷰
	///   - window: 기준 윈도우
	///   - keyboardHeight: 키보드 높이
	/// - Returns: NSLayoutConstraint 배열
	private func makePlatformToastConstraints(
		for toastView: UIView,
		in window: UIWindow,
		keyboardHeight: CGFloat
	) -> [NSLayoutConstraint] {
		if UIDevice.current.userInterfaceIdiom == .pad {
			let topInset = window.safeAreaInsets.top
			return [
				toastView.topAnchor.constraint(equalTo: window.topAnchor, constant: topInset + 32)
			] + horizontalConstraints(for: toastView, in: window)
		} else {
			let bottomOffset = calculateToastBottomOffset(for: window, keyboardHeight: keyboardHeight)
			return makeToastConstraints(for: toastView, in: window, bottomOffset: bottomOffset)
		}
	}
	/// 토스트 UI를 구성하여 반환
	/// - Parameters:
	///   - type: 토스트 타입 (성공, 경고 등)
	///   - title: 제목 텍스트
	///   - message: 본문 메시지
	/// - Returns: 완성된 토스트 UIView
	private func buildToastView(type: ToastType, title: String, message: String) -> UIView {
		let container = UIView()
		   container.backgroundColor = type.backgroundColor
		   container.layer.cornerRadius = 12
		   container.clipsToBounds = true
		   container.alpha = 0

		   let iconView = UIImageView()
		   let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
		   iconView.image = UIImage(systemName: type.iconName, withConfiguration: config)
		   iconView.tintColor = type.tintColor

		   iconView.setContentHuggingPriority(.required, for: .horizontal)
		   iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
		   iconView.translatesAutoresizingMaskIntoConstraints = false
		   iconView.widthAnchor.constraint(equalToConstant: 20).isActive = true
		   iconView.heightAnchor.constraint(equalToConstant: 20).isActive = true

		   let titleLabel = UILabel()
		   titleLabel.text = title
		   titleLabel.font = .boldSystemFont(ofSize: 16)
		   titleLabel.textColor = .white
		   titleLabel.numberOfLines = 0
		   titleLabel.textAlignment = .center

		   let messageLabel = UILabel()
		   messageLabel.text = message
		   messageLabel.font = .systemFont(ofSize: 14)
		   messageLabel.textColor = .white.withAlphaComponent(0.8)
		   messageLabel.numberOfLines = 0
		   messageLabel.textAlignment = .center

		   let titleStack = UIStackView(arrangedSubviews: [iconView, titleLabel])
		   titleStack.axis = .horizontal
		   titleStack.alignment = .center
		   titleStack.spacing = 8

		   let verticalStack = UIStackView(arrangedSubviews: [titleStack, messageLabel])
		   verticalStack.axis = .vertical
		   verticalStack.alignment = .center
		   verticalStack.spacing = 4

		   container.addSubview(verticalStack)
		   verticalStack.translatesAutoresizingMaskIntoConstraints = false

		   NSLayoutConstraint.activate([
			   verticalStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
			   verticalStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
			   verticalStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
			   verticalStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
		   ])

		   return container
	}
	/// 토스트를 페이드 인/아웃 애니메이션과 함께 보여줍니다.
	/// - Parameters:
	///   - view: 토스트 뷰
	///   - duration: 보여지는 시간
	private func animateToast(view: UIView, duration: TimeInterval) {
		UIView.animate(withDuration: 0.3, animations: {
			view.alpha = 1
		}) { _ in
			UIView.animate(
				withDuration: 0.3,
				delay: duration,
				options: .curveEaseOut,
				animations: {
					view.alpha = 0
				},
				completion: { _ in
					view.removeFromSuperview()
				}
			)
		}
	}
}
