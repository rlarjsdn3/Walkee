//
//  CAGradientLayer+Extension.swift
//  Health
//
//  Created by Seohyun Kim on 8/1/25.
//
import UIKit

extension CAGradientLayer {
	
	// MARK: - Gradient Types
	enum GradientType: String {
		case midnightBlack = "midnightBlack"
		case activityRing = "activityRing"
	}
	
	// MARK: - Convenience Initializers
	@MainActor
	convenience init(gradientType: GradientType, frame: CGRect = .zero) {
		self.init()
		self.frame = frame
		
		// 그라디언트 타입 정보 저장 - 업데이트시 사용
		self.setValue(gradientType.rawValue, forKey: "gradientType")
		
		setupGradient(type: gradientType)
	}
	
	// MARK: - Setup Methods
	@MainActor
	private func setupGradient(type: GradientType) {
		switch type {
		case .midnightBlack:
			setupMidnightBlackGradient()
		case .activityRing:
			setupActivityRingGradient()
		}
	}
	
	@MainActor
	private func setupMidnightBlackGradient() {
		// 다크모드 감지 (더 정확한 방법)
		let isDarkMode: Bool
		if #available(iOS 13.0, *) {
			// UIWindow나 현재 뷰컨트롤러의 trait collection 사용
			if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
			   let window = windowScene.windows.first {
				isDarkMode = window.traitCollection.userInterfaceStyle == .dark
			} else {
				isDarkMode = UIScreen.main.traitCollection.userInterfaceStyle == .dark
			}
		} else {
			isDarkMode = false
		}
		
		if isDarkMode {
			// 다크 모드: 그라디언트 적용 (위쪽이 더 어둡게)
			let darkColors = UIColor.GradientColors.midnightBlackDark.reversed()
			colors = darkColors.map { color in
				if #available(iOS 13.0, *) {
					return color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).cgColor
				} else {
					return color.cgColor
				}
			}
			locations = [0.0, 0.25, 1.0]
		} else {
			// 라이트 모드: 흰색 단색
			let lightColor = UIColor.GradientColors.midnightBlackLight
			let resolvedColor: CGColor
			if #available(iOS 13.0, *) {
				resolvedColor = lightColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)).cgColor
			} else {
				resolvedColor = lightColor.cgColor
			}
			colors = [resolvedColor, resolvedColor]
			locations = [0.0, 1.0]
		}
		
		startPoint = CGPoint(x: 0.5, y: 0.0)
		endPoint = CGPoint(x: 0.5, y: 1.0)
	}
	
	@MainActor
	private func setupActivityRingGradient() {
		// 다크모드 감지
		let isDarkMode: Bool
		if #available(iOS 13.0, *) {
			isDarkMode = UIScreen.main.traitCollection.userInterfaceStyle == .dark
		} else {
			isDarkMode = false
		}
		
		if isDarkMode {
			colors = UIColor.GradientColors.activityRingDark.map { $0.cgColor }
		} else {
			colors = UIColor.GradientColors.activityRingLight.map { $0.cgColor }
		}
		
		locations = [0.25, 0.54, 1.0]
		startPoint = CGPoint(x: 0.0, y: 0.0)
		endPoint = CGPoint(x: 1.0, y: 1.0)
		type = .conic // 원형 그라디언트를 위해
	}
	
	// MARK: - Dynamic Update for Theme Changes
	@MainActor
	func updateForCurrentTraitCollection() {
		// 그라디언트 타입을 저장된 정보로 다시 설정
		if let gradientTypeRaw = self.value(forKey: "gradientType") as? String {
			if gradientTypeRaw == "midnightBlack" {
				setupMidnightBlackGradient()
			} else if gradientTypeRaw == "activityRing" {
				setupActivityRingGradient()
			}
		} else {
			// locations 기반으로 추정
			if locations?.contains(0.25) == true && (colors?.count == 3 || colors?.count == 2) {
				// midnightBlack 그라디언트로 추정 (0.25 위치가 있거나 2-3개 색상)
				setupMidnightBlackGradient()
			} else if locations?.contains(0.54) == true {
				// activityRing 그라디언트로 추정
				setupActivityRingGradient()
			}
		}
	}
}

// MARK: - UIView Extension 그라디언트
extension UIView {
	
	@MainActor
	func applyGradientBackground(_ gradientType: CAGradientLayer.GradientType) {
		removeGradientBackground()
		
		let gradientLayer = CAGradientLayer(gradientType: gradientType, frame: bounds)
		gradientLayer.name = "gradientBackground"
		layer.insertSublayer(gradientLayer, at: 0)
	}
	
	func removeGradientBackground() {
		layer.sublayers?.removeAll { $0.name == "gradientBackground" }
	}
	
	func updateGradientFrame() {
		if let gradientLayer = layer.sublayers?.first(where: { $0.name == "gradientBackground" }) as? CAGradientLayer {
			gradientLayer.frame = bounds
		}
	}
	
	// MARK: - Theme Update Helper
	func updateGradientForTraitCollection() {
		if let gradientLayer = layer.sublayers?.first(where: { $0.name == "gradientBackground" }) as? CAGradientLayer {
			gradientLayer.updateForCurrentTraitCollection()
		}
	}
	
	func reapplyGradientForTraitCollection(_ gradientType: CAGradientLayer.GradientType) {
		// 기존 그라디언트 제거 후 다시 적용
		removeGradientBackground()
		applyGradientBackground(gradientType)
	}
}

// MARK: - UIViewController Helper for Theme Updates
extension UIViewController {
	// 이 메서드를 ViewController의 traitCollectionDidChange에서 호출
	func handleGradientTraitCollectionChange() {
		updateGradientsInView(view)
	}
	
	// 그라디언트 타입을 알고 있을 때
	func reapplyGradientForTraitCollectionChange(_ gradientType: CAGradientLayer.GradientType) {
		view.reapplyGradientForTraitCollection(gradientType)
	}
	
	private func updateGradientsInView(_ view: UIView) {
		// 현재 뷰의 그라디언트 업데이트
		view.updateGradientForTraitCollection()
		
		// 서브뷰들도 재귀적으로 확인
		view.subviews.forEach { updateGradientsInView($0) }
	}
}
