//
//  BarChartsView+Configiuration.swift
//  BarChartViewProject
//
//  Created by 김건우 on 8/1/25.
//

import UIKit

extension BarChartsView {

    /// 바 차트의 외형 및 표시 관련 설정을 정의하는 구성 구조체입니다.
    ///
    /// 막대 너비, 점선 스타일, 라벨 폰트 및 색상, 값 표시 여부 등의 설정을 포함합니다.
    struct Configuration {

        /// 차트 내 각 라벨에 대한 폰트 및 색상 스타일을 정의하는 구조체입니다.
        struct TextStyle {
            /// x축 라벨의 폰트입니다.
            var xAxisLabelFont: UIFont
            /// x축 라벨의 텍스트 색상입니다.
            var xAxisLabelTint: UIColor
            /// 막대 위에 표시되는 값 라벨의 폰트입니다.
            var valueLabelFont: UIFont
            /// 값 라벨의 텍스트 색상입니다.
            var valueLabelTint: UIColor
            /// 기준선 라벨의 폰트입니다.
            var limitLabelFont: UIFont
            /// 기준선 라벨의 텍스트 색상입니다.
            var limitLabelTint: UIColor

            /// 라벨 스타일을 초기화합니다.
            ///
            /// - Parameters:
            ///   - xAxisLabelFont: x축 라벨에 사용할 폰트
            ///   - xAxisLabelTint: x축 라벨의 색상
            ///   - valueLabelFont: 값 라벨에 사용할 폰트
            ///   - valueLabelTint: 값 라벨의 색상
            ///   - limitLabelFont: 기준선 라벨에 사용할 폰트
            ///   - limitLabelTint: 기준선 라벨의 색상
            init(
                xAxisLabelFont: UIFont = .preferredFont(forTextStyle: .caption1),
                xAxisLabelTint: UIColor = .label,
                valueLabelFont: UIFont = .preferredFont(forTextStyle: .caption1),
                valueLabelTint: UIColor = .label,
                limitLabelFont: UIFont = .preferredFont(forTextStyle: .caption2),
                limitLabelTint: UIColor = .secondaryLabel
            ) {
                self.xAxisLabelFont = xAxisLabelFont
                self.xAxisLabelTint = xAxisLabelTint
                self.valueLabelFont = valueLabelFont
                self.valueLabelTint = valueLabelTint
                self.limitLabelFont = limitLabelFont
                self.limitLabelTint = limitLabelTint
            }
        }

        /// 차트 표시 여부 등의 옵션을 제어하는 구조체입니다.
        struct DisplayOptions {
            /// 값 라벨을 표시할지 여부입니다.
            var showValueLabel: Bool

            /// 표시 옵션을 초기화합니다.
            ///
            /// - Parameter showValueLabel: 막대 위에 값 라벨을 표시할지 여부 (기본값: false)
            init(showValueLabel: Bool = false) {
                self.showValueLabel = showValueLabel
            }
        }

        /// 막대의 너비입니다.
        var barWidth: CGFloat
        /// 점선의 두께입니다.
        var dashedLineWidth: CGFloat
        /// 점선의 색상입니다.
        var dashedLineStrokeColor: UIColor
        /// 라벨에 대한 폰트 및 색상 스타일입니다.
        var textStyle: TextStyle
        /// 차트 표시 옵션입니다.
        var dispalyOptions: DisplayOptions

        /// 구성 값을 초기화합니다.
        ///
        /// - Parameters:
        ///   - barWidth: 막대의 너비
        ///   - dashedLineWidth: 점선의 두께
        ///   - dashedLineStrokeColor: 점선의 색상
        ///   - textStyle: 라벨 스타일 설정
        ///   - displayOptions: 값 표시 여부 등 표시 설정
        init(
            barWidth: CGFloat = 18,
            dashedLineWidth: CGFloat = 1,
            dashedLineStrokeColor: UIColor = .secondaryLabel,
            textStyle: TextStyle = .default(),
            displayOptions: DisplayOptions = .default()
        ) {
            self.barWidth = barWidth
            self.dashedLineWidth = dashedLineWidth
            self.dashedLineStrokeColor = dashedLineStrokeColor
            self.textStyle = textStyle
            self.dispalyOptions = displayOptions
        }
    }
}

extension BarChartsView.Configuration {

    /// 기본 구성 값을 반환합니다.
    static func `default`() -> BarChartsView.Configuration {
        BarChartsView.Configuration()
    }
}

extension BarChartsView.Configuration.TextStyle {

    /// 기본 텍스트 스타일 설정을 반환합니다.
    static func `default`() -> BarChartsView.Configuration.TextStyle {
        BarChartsView.Configuration.TextStyle()
    }
}

extension BarChartsView.Configuration.DisplayOptions {

    /// 기본 표시 옵션 설정을 반환합니다.
    static func `default`() -> BarChartsView.Configuration.DisplayOptions {
        BarChartsView.Configuration.DisplayOptions()
    }
}
