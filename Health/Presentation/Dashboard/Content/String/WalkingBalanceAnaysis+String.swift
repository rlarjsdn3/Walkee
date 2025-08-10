//
//  WalkingBalanceAnalysis+String.swift
//  Health
//
//  Created by 김건우 on 8/8/25.
//

import Foundation

typealias WalkingBalanceAnaysisString = String.WalkingBalanceAnalysis
extension String {

    struct WalkingBalanceAnalysis {
        static let walkingSpeed = "보행 속도는 일정 시간 동안 걷는 거리로, 전반적인 이동 능력과 체력 수준을 보여줍니다. 속도가 지나치게 느리면 낙상 위험과 근감소증 가능성이 높아집니다."
        static let stepLength = "보행 보폭은 한 걸음의 길이를 의미하며, 균형과 근력의 지표입니다. 보폭이 짧아지면 보행 불안정과 낙상 위험이 증가할 수 있습니다."
        static let doubleSupportPercentage = "이중 지지 시간은 두 발이 동시에 지면에 닿아 있는 시간 비율로, 균형 유지 능력을 나타냅니다. 수치가 높으면 균형 감각 저하나 낙상 위험을 의심할 수 있습니다."
        static let walkingAsymmetryPercentage = "보행 비대칭성은 양발의 사용 시간 차이를 나타내며, 보행의 균형과 협응력을 평가합니다. 비대칭 수치가 높을수록 넘어짐 등의 위험이 커질 수 있습니다."
    }
}
