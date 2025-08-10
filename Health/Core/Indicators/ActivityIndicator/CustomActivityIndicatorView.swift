//
//  CustomActivityIndicatorView.swift
//  Health
//
//  Created by Seohyun Kim on 8/10/25.
//
import UIKit

/// Custom Indication UIView
final class CustomActivityIndicatorView: UIView {
	var color: UIColor = .white {
		didSet { if isAnimating { restart() } }
	}
	
	/// 점 하나의 지름 단위(pt)
	var dotDiameter: CGFloat = 20 {
		didSet { invalidateIntrinsicContentSize(); if isAnimating { restart() } }
	}
	
	/// 내부 애니메이션 - 필요시 교체 가능
	private var animation: ActivityIndicatorAnimationDelegate = ActivityIndicatorAnimation()
	
	// MARK: - State
	private(set) var isAnimating: Bool = false
	
	// MARK: - Init
	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		commonInit()
	}
	
	// MARK: 접근성 기반 코드 (로딩 중이라는 것을 시각장애인은 들을 수 없으니 넣어봤어요.)
	// accessibilityTraits: 로딩 스피너는 시각적으로만 돌아가지만, 시각장애인 사용자는 "로딩 중"이라고 들을 수 있음.
	// accessibilityLabel:  VoiceOver가 이 요소를 설명할 때 읽는 텍스트 라벨
	// MARK: 그 외 속성 - 초기 표시 상태, 드로잉(크기 업데이트가 되면 다시 그려짐)
	private func commonInit() {
		isAccessibilityElement = true
		accessibilityTraits.insert(.updatesFrequently)
		accessibilityLabel = "로딩 중"
		isHidden = true
		backgroundColor = .clear
		contentMode = .redraw
	}
	
	// MARK: - Layout
	/// 뷰 자체의 특성만 고려하여 반환되는 **자연스러운 크기**(intrinsic content size)를 제공
	///
	/// 이 프로퍼티는 오토레이아웃에서 명시적인 크기 제약이 없을 때,
	/// 뷰가 이상적으로 차지해야 하는 기본 크기를 시스템에 알림.
	///
	/// - 중요: 커스텀 뷰를 만들 때, 콘텐츠나 외부 제약과 무관하게
	///   뷰 자체가 선호하는 크기가 있을 경우 이 프로퍼티를 재정의(override)
	/// - 반환값: 뷰의 이상적인 너비와 높이를 나타내는 `CGSize`.
	///  인디케이터 점(도형)의 지름 기준, 점이 커지고 겹치는 공간 포함해 약 2.2배 확장됨
	///  최소 24pt 이상
	///  예: dotDiameter가 10pt이면, 10 x 22 = 22pt면  최소 24 pt로 반환
	override var intrinsicContentSize: CGSize {
		let side = max(dotDiameter * 2.2, 24)
		return CGSize(width: side, height: side)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		if isAnimating {
			restart()
		}
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		if isAnimating, previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
			restart()
		}
	}
	
	// MARK: - Control
	
	func startAnimating() {
		guard !isAnimating else { return }
		isHidden = false
		layer.sublayers?.forEach { $0.removeFromSuperlayer() }
		let size = CGSize(width: dotDiameter, height: dotDiameter)
		animation.setUpAnimation(in: layer, size: size, color: color)
		isAnimating = true
		accessibilityValue = "진행 중"
	}
	
	func stopAnimating() {
		guard isAnimating else { return }
		layer.sublayers?.forEach {
			$0.removeAllAnimations()
			$0.removeFromSuperlayer()
		}
		isAnimating = false
		isHidden = true
		accessibilityValue = "중지됨"
	}
	
	private func restart() {
		stopAnimating()
		startAnimating()
	}
	
	override func didMoveToWindow() {
		super.didMoveToWindow()
		if window == nil { stopAnimating() }
	}
}
