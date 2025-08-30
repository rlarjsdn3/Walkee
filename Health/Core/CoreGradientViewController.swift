//
//  CoreGradientViewController.swift
//  Health
//
//  Created by Seohyun Kim on 8/1/25.
//
import UIKit
/**
 그라디언트/단색 배경 처리를 지원하는 기반 뷰 컨트롤러.

 `CoreGradientViewController`는 `CoreViewController`를 상속하며,
 다크 모드 전환 및 traitCollection 변화에 대응해
 배경 그라디언트를 자동으로 갱신하는 기능을 제공한다.

 ## 주요 기능
 - `applyBackgroundGradient(_:)` 메서드로 지정한 타입의 그라디언트 배경 적용
 - `applySolidBackground(_:)` 메서드로 단색 배경 적용
 - 다크 모드 전환 시 그라디언트 색상 자동 갱신
 - 다이나믹 컬러를 `cgColor`로 안전하게 변환하는 헬퍼 제공
 - `onThemeChanged(isDarkMode:previousTraitCollection:)` 오버라이드 지점 제공

 ## 상속 구조
 ```text
 UIViewController
   └── CoreViewController
		 └── CoreGradientViewController
 */
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
	
	/// 배경에 그라디언트를 적용한다.
	/// - Parameter gradientType: 적용할 `CAGradientLayer.GradientType`
	func applyBackgroundGradient(_ gradientType: CAGradientLayer.GradientType) {
		currentGradientType = gradientType
		view.applyGradientBackground(gradientType)
		
		if #available(iOS 13.0, *) {
			let _ = traitCollection.userInterfaceStyle == .dark
		}
	}
	
	/// 단색 배경을 적용한다.
	/// - Parameter color: 적용할 `UIColor`
	func applySolidBackground(_ color: UIColor) {
		currentGradientType = nil
		view.removeGradientBackground()
		view.backgroundColor = color
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
	
	/// 여러 다이나믹 컬러들을 `CGColor` 배열로 변환
	/// - Parameter colors: UIColor 배열 (다이나믹 컬러 가능)
	/// - Returns: 현재 trait collection에 맞는 CGColor 배열
	func dynamicCGColors(from colors: [UIColor]) -> [CGColor] {
		return colors.map { dynamicCGColor(from: $0) }
	}
	
	// MARK: - Private Methods

	/// 현재 적용된 그라디언트 타입이 있으면
	/// 뷰의 크기 변경에 맞춰 그라디언트 레이어 프레임을 갱신한다.
	///
	/// - Note: `viewDidLayoutSubviews()`에서 호출됨.
	private func updateGradientFrameIfNeeded() {
		if currentGradientType != nil {
			view.updateGradientFrame()
		}
	}
	/// 다크 모드/라이트 모드 전환 등 TraitCollection 변경 시
	/// 현재 그라디언트를 다시 적용한다.
	///
	/// - Parameters:
	///   - previousTraitCollection: 이전 trait collection 값
	///
	/// 내부적으로 `view.reapplyGradientForTraitCollection(_:)`를 호출하고,
	/// 이후 `onThemeChanged(isDarkMode:previousTraitCollection:)` 훅을 통해
	/// 서브클래스 커스텀 로직 실행 기회를 제공한다.
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
		// 서브클래스에서 오버라이드해서 추가 로직 구현할 때 쓰는 메서드임
	}
}
