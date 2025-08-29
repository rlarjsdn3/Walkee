//
//  Duration+Extension.swift
//  Health
//
//  Created by Seohyun Kim on 8/28/25.
//

import Foundation

extension Duration {
	var milliseconds: Double {
		let (s, attos) = components
		return Double(s) * 1000.0 + Double(attos) / 1e15
	}
}
