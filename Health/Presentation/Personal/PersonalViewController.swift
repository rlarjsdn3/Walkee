//
//  PersonalViewController.swift
//  Health
//
//  Created by Seohyun Kim on 8/1/25.
//
import UIKit

class PersonalViewController: CoreGradientViewController {



    @IBAction func segmentControl(_ sender: Any) {
    }
    

    @IBAction func leftChevron(_ sender: Any) {
    }
    

    @IBAction func rightChevron(_ sender: Any) {
    }
    
    @IBOutlet weak var selectLabel: UILabel!
    
    @IBOutlet weak var statisticsView: UIView!

    @IBOutlet weak var walkingDataContainerView: UIView!
    
    @IBOutlet weak var walkingLabel: UILabel!
    
    @IBOutlet weak var distanceLabel: UILabel!

    override func initVM() {
		super.initVM()

	}
	
	override func setupAttribute() {
		super.setupAttribute()
		
		print("PersonalViewController 속성 설정 시작")
		
		applyBackgroundGradient(.midnightBlack)
		setupUI()
		
		print("PersonalViewController 속성 설정 완료")
	}
	
	override func onThemeChanged(isDarkMode: Bool, previousTraitCollection: UITraitCollection?) {
		super.onThemeChanged(isDarkMode: isDarkMode, previousTraitCollection: previousTraitCollection)
		
		print("PersonalViewController 테마 변경 처리: \(isDarkMode ? "다크모드" : "라이트모드")")
		
		updateUIForTheme(isDarkMode: isDarkMode)
	}

	// 기타 UI 설정 시 이곳에서 사용합니다.
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
