//
//  CoreGradientViewController.swift
//  Health
//
//  Created by Seohyun Kim on 8/1/25.
//

import UIKit

class CoreGradientViewController: CoreViewController {
	
	private var currentGradientType: CAGradientLayer.GradientType?
	private var currentTraitCollection: UITraitCollection?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		currentTraitCollection = traitCollection
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		updateGradientFrameIfNeeded()
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		
		if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
			currentTraitCollection = traitCollection
			handleThemeChange(previousTraitCollection: previousTraitCollection)
		}
	}
	
	// MARK: - Gradient Methods (서브클래스에서 사용할 때)
	
	/// 배경에 그라디언트를 적용
	/// - Parameter gradientType: 적용할 그라디언트 타입
	func applyBackgroundGradient(_ gradientType: CAGradientLayer.GradientType) {
		currentGradientType = gradientType
		view.applyGradientBackground(gradientType)
		
		if #available(iOS 13.0, *) {
			let isDarkMode = traitCollection.userInterfaceStyle == .dark
			print("[\(String(describing: type(of: self)))] 그라디언트 적용: \(gradientType.rawValue), 다크모드: \(isDarkMode)")
		}
	}
	
	/// 단색 배경을 적용
	/// - Parameter color: 적용할 배경색
	func applySolidBackground(_ color: UIColor) {
		currentGradientType = nil
		view.removeGradientBackground()
		view.backgroundColor = color
		
		print("[\(String(describing: type(of: self)))] 단색 배경 적용: \(color)")
	}
	
	/// 다이나믹 컬러를 cgColor로 변환
	/// - Parameter color: UIColor
	/// - Returns: 현재 trait collection에 맞는 CGColor
	func dynamicCGColor(from color: UIColor) -> CGColor {
		if #available(iOS 13.0, *) {
			return color.resolvedColor(with: currentTraitCollection ?? traitCollection).cgColor
		} else {
			return color.cgColor
		}
	}
	
	/// 여러 다이나믹 컬러들을 cgColor 배열로 변환
	/// - Parameter colors: UIColor 배열 (다이나믹 컬러 가능)
	/// - Returns: 현재 trait collection에 맞는 CGColor 배열
	func dynamicCGColors(from colors: [UIColor]) -> [CGColor] {
		return colors.map { dynamicCGColor(from: $0) }
	}
	
	// MARK: - Private Methods
	private func updateGradientFrameIfNeeded() {
		if currentGradientType != nil {
			view.updateGradientFrame()
		}
	}
	
	private func handleThemeChange(previousTraitCollection: UITraitCollection?) {
		guard let gradientType = currentGradientType else { return }
		
		let isDarkMode = traitCollection.userInterfaceStyle == .dark
		
		// 그라디언트 재적용 - cgColor 업데이트
		view.reapplyGradientForTraitCollection(gradientType)
		
		// 서브클래스에서 추가 처리가 필요한 경우
		onThemeChanged(isDarkMode: isDarkMode, previousTraitCollection: previousTraitCollection)
	}
	
	/// 테마 변경시 호출되는 메서드
	/// - Parameters:
	///   - isDarkMode: 현재 다크모드 여부
	///   - previousTraitCollection: 이전 trait collection
	func onThemeChanged(isDarkMode: Bool, previousTraitCollection: UITraitCollection?) {
		// 서브클래스에서 오버라이드해서 추가 로직 구현할 때 쓰는 임시 메서드임
	}
}
