//
//  ActivityIndicatorAnimation.swift
//  Health
//
//  Created by Seohyun Kim on 8/10/25.
//

import UIKit

final class ActivityIndicatorAnimation: ActivityIndicatorAnimationDelegate {
	func setUpAnimation(in layer: CALayer, size: CGSize, color: UIColor) {
		let duration: CFTimeInterval = 1.0
		let beginTime = CACurrentMediaTime()
		let offsets: [CFTimeInterval] = [0.0, 0.22, 0.44]
		
		// Scale
		let scale = CABasicAnimation(keyPath: "transform.scale")
		scale.duration = duration
		scale.fromValue = 0.2
		scale.toValue = 1.0
		
		// Opacity
		let opacity = CAKeyframeAnimation(keyPath: "opacity")
		opacity.duration = duration
		opacity.keyTimes = [0, 0.12, 1]
		opacity.values = [0, 1, 0]
		
		// Group
		let group = CAAnimationGroup()
		group.animations = [scale, opacity]
		group.timingFunction = CAMediaTimingFunction(name: .linear)
		group.duration = duration
		group.repeatCount = .infinity
		group.isRemovedOnCompletion = false
		
		// 3개의 점을 중앙에 겹쳐서 순차 재생
		for i in 0..<3 {
			let dot = ActivityIndicatorShape.circle.makeLayer(size: size, color: color)
			let frame = CGRect(
				x: (layer.bounds.width  - size.width)  / 2.0,
				y: (layer.bounds.height - size.height) / 2.0,
				width: size.width,
				height: size.height
			)
			group.beginTime = beginTime + offsets[i]
			dot.frame = frame
			dot.opacity = 0
			dot.add(group, forKey: "wave")
			layer.addSublayer(dot)
		}
	}
}
