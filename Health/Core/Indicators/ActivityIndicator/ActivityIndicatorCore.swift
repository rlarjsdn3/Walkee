//
//  ActivityIndicatorCore.swift
//  Health
//
//  Created by Seohyun Kim on 8/10/25.
//
import UIKit


/// custom Indicator animation protocol
protocol ActivityIndicatorAnimationDelegate: AnyObject {
	func setUpAnimation(in layer: CALayer, size: CGSize, color: UIColor)
}


/// indicator dot / shape - Util 
enum ActivityIndicatorShape {
	case circle
	
	func makeLayer(size: CGSize, color: UIColor) -> CALayer {
		switch self {
		case .circle:
			let shape = CAShapeLayer()
			shape.path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).cgPath
			
			shape.fillColor = color.cgColor
			shape.bounds = CGRect(origin: .zero, size: size)
			return shape
		}
	}
}
