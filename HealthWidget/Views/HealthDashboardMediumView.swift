//
//  HealthDashboardMediumView.swift
//  Health
//
//  Created by Nat Kim on 8/23/25.
//

import SwiftUI
import WidgetKit

// 측정 키
private struct RightContentWidthKey: PreferenceKey {
	static var defaultValue: CGFloat = 0
	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct WeeklyAvgWidthKey: PreferenceKey {
	static var defaultValue: CGFloat = 0
	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct WeeklyTrailingKey: PreferenceKey {
	static var defaultValue: CGFloat = 0
	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct HealthDashboardMediumView: View {
	let snapShot: HealthDashboardSnapshot

	@State private var rightContentWidth: CGFloat = 0
	@State private var weeklyAvgWidth: CGFloat = 0
	@State private var weeklyTrailing: CGFloat = 0
	@State private var containerTrailing: CGFloat = 0
	@State private var rightTrailing: CGFloat = 16
	private var progress: Double {
		guard snapShot.goalSteps > 0 else { return 0 }
		return min(1, max(0, Double(snapShot.stepsToday) / Double(snapShot.goalSteps)))
	}

	var body: some View {
		GeometryReader { geo in
			let M = AdaptiveMetrics(size: geo.size)

			let contentW = geo.size.width - (M.outerPadding.leading + M.outerPadding.trailing)
			let leftWidth: CGFloat = max(0, contentW * 0.53)
			let dividerW = M.dividerWidth
			let spacing  = M.leftRightSpacing
			let rightWidth: CGFloat = max(0, contentW - leftWidth - dividerW - spacing)

			let gapTopToBar = min(max(geo.size.height * 0.085, 10), 16)

			VStack(spacing: 0) {
				HStack(alignment: .top, spacing: M.leftRightSpacing) {

					VStack(alignment: .leading, spacing: M.metricRowSpacing) {
						metricRow(M: M, symbol: "figure.walk.circle.fill",
								  title: "거리", valueText: snapShot.distanceText, unit: "km")
						metricRow(M: M, symbol: "timer.circle.fill",
								  title: "운동 시간", valueText: snapShot.exerciseMinuteText, unit: "분")
						metricRow(M: M, symbol: "flame.circle.fill",
								  title: "활동 에너지", valueText: snapShot.activeKcalText, unit: "kcal")
					}
					.frame(width: leftWidth, alignment: .leading)

					Rectangle()
						.fill(Color.secondary.opacity(0.6))
						.frame(width: dividerW, height: M.dividerHeight)

					ZStack {
						rightContent(M: M, snapShot: snapShot)
							.fixedSize(horizontal: true, vertical: true)
							.background(
								GeometryReader { g in
									Color.clear
										.preference(key: RightContentWidthKey.self, value: g.size.width)
								}
							)
					}
					.frame(width: rightWidth, alignment: .center)
				}

				Spacer(minLength: gapTopToBar)

				ProgressBar(progress: progress, height: M.progressHeight, fill: .accent)
					.padding(.trailing, rightTrailing)

				Spacer(minLength: M.progressToBottomLabelGap)

				HStack {
					Text("목표 걸음 수")
						.font(.system(size: M.goalLabelSize, weight: .heavy))
						.foregroundStyle(.primary)
						.lineLimit(1)
						.minimumScaleFactor(0.9)

					Spacer()

					(
						Text(snapShot.stepsTodayText)
							.font(.system(size: M.goalStatSize, weight: .semibold))
							.monospacedDigit()
							.foregroundStyle(.secondary)
						+
						Text(" / ")
							.font(.system(size: M.goalStatSize))
							.foregroundStyle(.secondary)
						+
						Text(snapShot.goalStepsText)
							.font(.system(size: M.goalStatSize, weight: .heavy))
							.monospacedDigit()
							.foregroundStyle(.teal)
					)
					.lineLimit(1)
					.minimumScaleFactor(0.75)
					.allowsTightening(true)
				}
				.padding(.trailing, rightTrailing)
			}
			.padding(M.outerPadding)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(
				GeometryReader { geo in
					Color.clear
						.onAppear {
							containerTrailing = geo.frame(in: .global).maxX
						}
						.onChange(of: weeklyTrailing) { oldValue, newValue in
							rightTrailing = max(0, containerTrailing - weeklyTrailing - M.outerPadding.trailing)
						}
				}
			)
			.onPreferenceChange(RightContentWidthKey.self) { rightContentWidth = $0 }
			.onPreferenceChange(WeeklyAvgWidthKey.self) { weeklyAvgWidth = $0 }
			.onPreferenceChange(WeeklyTrailingKey.self) { weeklyTrailing = $0 }
		}
	}

	private func rightContent(M: AdaptiveMetrics, snapShot: HealthDashboardSnapshot) -> some View {
		VStack(alignment: .center, spacing: max(4, M.iconTextSpacing * 0.8)) {
			Text("오늘 걸음 수")
				.font(.system(size: M.todayTitleSize, weight: .semibold))
				.foregroundStyle(.secondary)
				.lineLimit(1)
				.minimumScaleFactor(0.9)
				.multilineTextAlignment(.center)

			Text(snapShot.stepsTodayText)
				.font(.system(size: M.todayStepSize, weight: .heavy))
				.monospacedDigit()
				.foregroundStyle(.teal)
				.lineLimit(1)
				.minimumScaleFactor(0.7)
				.multilineTextAlignment(.center)

			HStack(spacing: max(2, M.iconTextSpacing * 0.6)) {
				Text("주 평균")
					.font(.system(size: M.weeklyLabelSize, weight: .semibold))
					.foregroundStyle(.secondary)
					.lineLimit(1).minimumScaleFactor(0.9)

				Text(snapShot.weeklyAvgText)
					.font(.system(size: M.weeklyNumberSize, weight: .bold))
					.monospacedDigit()
					.foregroundStyle(.primary)
					.lineLimit(1).minimumScaleFactor(0.85)

				Text("걸음")
					.font(.system(size: M.weeklyLabelSize, weight: .semibold))
					.foregroundStyle(.secondary)
					.lineLimit(1).minimumScaleFactor(0.9)
					.background(
						GeometryReader { g in
							Color.clear
								.preference(key: WeeklyTrailingKey.self, value: g.frame(in: .global).maxX)
						}
					)
			}
			.fixedSize(horizontal: true, vertical: true)
			.background(
				GeometryReader { g in
					Color.clear
						.preference(key: WeeklyAvgWidthKey.self, value: g.size.width)
				}
			)
		}
	}

	private func metricRow(M: AdaptiveMetrics, symbol: String, title: String, valueText: String, unit: String) -> some View {
		HStack(alignment: .center, spacing: M.iconTextSpacing) {
			Image(systemName: symbol)
				.resizable().scaledToFit()
				.frame(width: M.symbolSize, height: M.symbolSize)
				.symbolRenderingMode(.palette)
				.foregroundStyle(.white, .teal)

			Text(title)
				.font(.system(size: M.titleFontSize, weight: .heavy))
				.foregroundStyle(.secondary)
				.lineLimit(1)
				.minimumScaleFactor(0.95)
				.layoutPriority(2)

			Spacer(minLength: 0)

			HStack(spacing: max(1, M.iconTextSpacing * 0.25)) {
				Text(valueText)
					.font(.system(size: M.valueFontSize, weight: .heavy))
					.monospacedDigit()
					.foregroundStyle(.primary)
					.lineLimit(1)
					.minimumScaleFactor(0.9)

				Text(unit)
					.font(.system(size: M.unitFontSize, weight: .semibold))
					.foregroundStyle(.secondary)
					.lineLimit(1)
					.minimumScaleFactor(0.9)
			}
			.fixedSize(horizontal: true, vertical: false)
		}
	}
}

private struct ProgressBar: View {
	let progress: Double
	let height: CGFloat
	let fill: Color

	var body: some View {
		GeometryReader { geo in
			ZStack(alignment: .leading) {
				Capsule().fill(Color(.systemGray4))
				Capsule()
					.fill(fill)
					.frame(width: geo.size.width * CGFloat(min(max(progress, 0), 1)))
			}
		}
		.frame(height: height)
	}
}
