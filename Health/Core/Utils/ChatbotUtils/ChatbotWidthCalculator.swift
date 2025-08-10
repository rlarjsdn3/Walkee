//
//  ChatbotWidthCalculator.swift
//  Health
//
//  Created by Nat Kim on 8/10/25.
//

import UIKit

/// 챗봇 셀들에서 공통으로 쓰는 최대 너비 계산기
struct ChatbotWidthCalculator {
	
	/// 디바이스/프로파일에 따른 “텍스트 컨텐츠” 기준의 최대 너비(패딩 제외)
	static func maxContentWidth(
		for profile: ChatbotWidthProfile,
		screenWidth: CGFloat = UIScreen.main.bounds.width
	) -> CGFloat {
		let cls = ScreenClass.from(screenWidth)
		
		// 기본 디바이스별 최소 상한값
		let baseMax: CGFloat = {
			switch cls {
			case .w320:  return 240
			case .w375:  return 280
			case .w414:  return 320
			case .wLarge: return 350
			}
		}()
		
		switch profile {
		case .userBubble:
			// 말풍선 - 버블UI
			return adjust(baseMax,
						  fallbackMultiplier: 0.75,
						  overrideFor414: 310,
						  overrideForLarge: 340,
						  screenWidth: screenWidth)
		case .aiResponseText, .loadingText:
			// 응답/로딩 텍스트
			return adjust(baseMax,
						  fallbackMultiplier: 0.75,
						  overrideFor414: 320,
						  overrideForLarge: 350,
						  screenWidth: screenWidth)
		case let .custom(multiplier, fixedMax):
			if let m = fixedMax { return m }
			return screenWidth * clamp(multiplier, min: 0.4, max: 0.95)
		}
	}
	
	/// 내부 패딩이 있는 말풍선 뷰의 “버블 전체 너비” 최대값
	static func maxBubbleWidth(
		for profile: ChatbotWidthProfile,
		horizontalContentPadding: CGFloat = 32,
		additionalMargins: CGFloat = 0,
		screenWidth: CGFloat = UIScreen.main.bounds.width
	) -> CGFloat {
		let contentMax = maxContentWidth(for: profile, screenWidth: screenWidth)
		return max(0, contentMax + horizontalContentPadding - additionalMargins)
	}
	
	// MARK: - Private helpers
	private static func clamp(_ v: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
		Swift.max(min, Swift.min(max, v))
	}
	
	private static func adjust(
		_ baseMax: CGFloat,
		fallbackMultiplier: CGFloat,
		overrideFor414: CGFloat,
		overrideForLarge: CGFloat,
		screenWidth: CGFloat
	) -> CGFloat {
		switch ScreenClass.from(screenWidth) {
		case .w320:  return baseMax        // 240
		case .w375:  return baseMax        // 280
		case .w414:  return overrideFor414 // 310 or 320
		case .wLarge: return overrideForLarge // 340 or 350
		}
	}
}

// MARK: - 내부 전용 타입
private enum ScreenClass {
	case w320, w375, w414, wLarge
	
	static func from(_ width: CGFloat) -> ScreenClass {
		switch width {
		case ...320:
			return .w320
		case 321...375:
			return .w375
		case 376...414:
			return .w414
		default:
			return .wLarge
		}
	}
}
