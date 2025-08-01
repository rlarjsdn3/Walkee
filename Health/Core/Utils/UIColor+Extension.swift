//
//  UIColor+Extension.swift
//  Health
//
//  Created by Seohyun Kim on 8/1/25.
//

import Foundation
import UIKit

extension UIColor {
	
	/// <#Description#>
	/// - Parameters:
	///   - hex: <#hex description#>
	///   - alpha: <#alpha description#>
	convenience init(hex: String, alpha: CGFloat = 1.0) {
		var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
		hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
		
		var rgb: UInt64 = 0
		
		Scanner(string: hexSanitized).scanHexInt64(&rgb)
		
		let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
		let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
		let blue = CGFloat(rgb & 0x0000FF) / 255.0
		
		self.init(red: red, green: green, blue: blue, alpha: alpha)
	}
	
	
	/// <#Description#>
	/// - Parameters:
	///   - light: <#light description#>
	///   - dark: <#dark description#>
	/// - Returns: <#description#>
	static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
		if #available(iOS 13.0, *) {
			return UIColor { traitCollection in
				return traitCollection.userInterfaceStyle == .dark ? dark : light
			}
		} else {
			return light
		}
	}
}

// MARK: - App Color Palette
extension UIColor {
	
	// MARK: - Background Gradient Colors
	struct GradientColors {
		
		// midnightBlack 그라디언트 (다크모드)
		static let midnightBlackLight = UIColor.white
		static let midnightBlackDark = [
			UIColor(hex: "000000"),    // 0%
			UIColor(hex: "222333"),    // 75%
			UIColor(hex: "292A3D")     // 100%
		]
		
		// 원형 액티비티 링 그라디언트 (70% opacity)
		static let activityRingLight = [
			UIColor.white.withAlphaComponent(0.7),
			UIColor.white.withAlphaComponent(0.7),
			UIColor.white.withAlphaComponent(0.7)
		]
		static let activityRingDark = [
			UIColor(hex: "7ACCCC").withAlphaComponent(0.7),    // 25%
			UIColor(hex: "9AD8D8").withAlphaComponent(0.7),    // 54%
			UIColor(hex: "FFFFFF").withAlphaComponent(0.7)     // 100%
		]
	}
	
	// MARK: - Computed Properties
	static var midnightBlackBackground: UIColor {
		return dynamicColor(
			light: GradientColors.midnightBlackLight,
			dark: UIColor.black
		)
	}
}

