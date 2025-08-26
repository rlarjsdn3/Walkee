//
//  ToastType.swift
//  Health
//
//  Created by Seohyun Kim on 8/26/25.
//

import Foundation
import UIKit

enum ToastType {
	case warning
	case success
	case info

	var iconName: String {
		switch self {
		case .warning: return "exclamationmark.triangle.fill"
		case .success: return "checkmark.circle.fill"
		case .info:    return "info.circle.fill"
		}
	}

	var backgroundColor: UIColor {
		switch self {
		case .warning: return UIColor.systemOrange.withAlphaComponent(0.9)
		case .success: return UIColor.systemGreen.withAlphaComponent(0.9)
		case .info:    return UIColor.systemBlue.withAlphaComponent(0.9)
		}
	}

	var tintColor: UIColor {
		switch self {
		case .warning: return .white
		case .success: return .white
		case .info:    return .white
		}
	}
}
