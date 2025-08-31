//
//  AdaptiveMetrics.swift
//  Health
//
//  Created by Seohyun Kim on 8/24/25.
//

import SwiftUI
/// 위젯 컨테이너 크기(`CGSize`)에 맞춰 **폰트/간격/패딩/바 높이** 등을
/// 일관된 비율로 산출하는 유틸리티.
///
/// - Important: 일부 값은 **요구사항에 따라 고정**(예: 좌/우 패딩 16pt, 행 간격 10pt)으로 둔다.
/// - Note: iPad·대형 위젯 컨테이너에서도 과도한 확대/축소를 방지하기 위해 `clamp`로 최소/최대값을 제한한다.
struct AdaptiveMetrics {
	let size: CGSize
	private var W: CGFloat { max(size.width, 1) }
	private var H: CGFloat { max(size.height, 1) }

	private func clamp(_ v: CGFloat, min lo: CGFloat, max hi: CGFloat) -> CGFloat {
		min(max(v, lo), hi)
	}

	// 패딩: 좌우는 고정 16pt, 상/하는 기기 폭/높이에 따라 보정
	var outerPadding: EdgeInsets {
		let top = clamp(W * 0.055, min: 10, max: 26)
		let side: CGFloat = 16    // <- 요구사항 반영: 항상 16pt
		let bottom = clamp(W * 0.045, min: 12, max: 24)
		return EdgeInsets(top: top, leading: side, bottom: bottom, trailing: side)
	}

	// 좌우 블록 간격(좌측 그룹 ↔ 우측 그룹)
	var leftRightSpacing: CGFloat { clamp(W * 0.050, min: 10, max: 16) } // 최대 16로 살짝 타이트하게

	// 아이콘/텍스트 간격
	var symbolSize: CGFloat       { clamp(W * 0.050, min: 14, max: 28) }
	var iconTextSpacing: CGFloat  { clamp(W * 0.022, min: 6,  max: 14) }

	// 행 간격 고정 10pt
	var metricRowSpacing: CGFloat { 10 }  // 요구사항 고정값

	// 좌측 열 폰트 — 값이 라벨보다 큼
	var titleFontSize: CGFloat    { clamp(W * 0.042, min: 13, max: 20) }
	var valueFontSize: CGFloat    { clamp(W * 0.052, min: 15, max: 24) }
	var unitFontSize: CGFloat     { clamp(W * 0.032, min: 10, max: 16) }

	// 우측 블록 폰트
	var todayTitleSize: CGFloat   { clamp(W * 0.040, min: 12, max: 20) }
	var todayStepSize: CGFloat    { clamp(W * 0.082, min: 22, max: 38) }
	var weeklyLabelSize: CGFloat  { clamp(W * 0.030, min: 9,  max: 16) }
	var weeklyNumberSize: CGFloat { clamp(W * 0.044, min: 12, max: 22) }

	// Divider
	var dividerWidth: CGFloat     { clamp(W * 0.004, min: 1,  max: 3) }
	var dividerHeight: CGFloat    { clamp(H * 0.46,  min: 56, max: H * 0.70) }

	// 프로그레스바 & 간격
	var progressHeight: CGFloat            { clamp(H * 0.070, min: 8,  max: 14) }
	var groupBottomGapToProgress: CGFloat  { clamp(H * 0.34,  min: 24, max: 70) }
	var progressToBottomLabelGap: CGFloat  { clamp(H * 0.040, min: 4,  max: 12) }

	// 하단 "목표 걸음 수"
	var goalLabelSize: CGFloat    { clamp(W * 0.030, min: 10, max: 14) }
	var goalStatSize: CGFloat     { clamp(W * 0.038, min: 12, max: 18) }
}
