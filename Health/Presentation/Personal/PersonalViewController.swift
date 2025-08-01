//
//  PersonalViewController.swift
//  Health
//
//  Created by Seohyun Kim on 8/1/25.
//
import UIKit

class PersonalViewController: CoreGradientViewController {

	// MARK: - Properties
	
	// MARK: - CoreViewController Override Methods
	
	override func initVM() {
		super.initVM()
		print("PersonalViewController ViewModel 초기화")
	}
	
	override func setupHierarchy() {
		super.setupHierarchy()
		print("PersonalViewController 뷰 계층 구성")
	}
	
	override func setupAttribute() {
		super.setupAttribute()
		
		print("PersonalViewController 속성 설정 시작")
		
		applyBackgroundGradient(.midnightBlack)
		setupUI()
		
		print("PersonalViewController 속성 설정 완료")
	}
	
	override func setupConstraints() {
		super.setupConstraints()
		print("PersonalViewController 제약 조건 설정")
	}
	
	override func onThemeChanged(isDarkMode: Bool, previousTraitCollection: UITraitCollection?) {
		super.onThemeChanged(isDarkMode: isDarkMode, previousTraitCollection: previousTraitCollection)
		
		print("PersonalViewController 테마 변경 처리: \(isDarkMode ? "다크모드" : "라이트모드")")
		
		updateUIForTheme(isDarkMode: isDarkMode)
	}
	
	// MARK: - Private Methods
	// 기타 UI 설정 시 이곳에서 사용합니다. (e.g. NSLayoutConstraint) - 삭제하고 쓰시거나 이 메서드 아예 지우셔도 무방해요.
	private func setupUI() {
		
	}
	
	private func updateUIForTheme(isDarkMode: Bool) {
		if isDarkMode {
			// 다크모드용 색상들을 cgColor로 안전하게 변환
			let darkTextColor = dynamicCGColor(from: .white)
			let darkButtonColors = dynamicCGColors(from: [UIColor.systemBlue, UIColor.systemGreen])
			
		} else {
			let lightTextColor = dynamicCGColor(from: .black)
			let lightButtonColors = dynamicCGColors(from: [UIColor.systemBlue, UIColor.systemGreen])
			
		}
	}
}
