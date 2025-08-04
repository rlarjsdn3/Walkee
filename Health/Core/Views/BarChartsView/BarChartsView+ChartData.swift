//
//  BarChartView+DataSet.swift
//  BarChartViewProject
//
//  Created by 김건우 on 8/1/25.
//

import UIKit

extension BarChartsView {

    /// 바 차트에 표시할 데이터를 표현하는 구조체입니다.
    ///
    /// 막대 그래프를 구성하는 개별 요소(`Element`)와 기준선 또는 목표선 정보(`Limit`)를 포함합니다.
    struct ChartData: Sendable {

        /// 개별 막대 데이터를 나타내는 구조체입니다.
        ///
        /// 값과 색상, x축에 표시할 라벨 및 해당 날짜 정보를 포함합니다.
        struct Element: Hashable, Sendable {
            /// 막대에 해당하는 값입니다.
            let value: Double
            /// 막대의 색상입니다.
            let color: UIColor
            /// x축에 표시할 텍스트 라벨입니다 (예: 요일).
            let xLabel: String?
            /// 해당 값이 속한 날짜입니다.
            let date: Date

            /// 새로운 막대 요소를 초기화합니다.
            ///
            /// - Parameters:
            ///   - value: 막대 값입니다.
            ///   - color: 막대 색상입니다. 기본값은 `.systemTeal`입니다.
            ///   - xLabel: x축 라벨에 표시할 문자열입니다. `nil`을 전달하면 `date`가 x축 라벨로 표시됩니다.
            ///   - date: 해당 막대와 연관된 날짜입니다.
            init(
                value: Double,
                color: UIColor = .systemTeal,
                xLabel: String? = nil,
                date: Date
            ) {
                self.value = value
                self.color = color
                self.xLabel = xLabel
                self.date = date
            }

            static func == (lhs: Element, rhs: Element) -> Bool {
                lhs.date == rhs.date
            }
        }

        /// 기준선 또는 목표선을 나타내는 구조체입니다.
        struct Limit: Sendable {
            /// 기준선의 값입니다.
            let value: Double
            /// 기준선에 함께 표시할 라벨입니다.
            let label: String?
        }

        /// 바 차트에 표시할 모든 막대 요소입니다.
        var elements: [Element]

        /// 기준선 또는 목표선 정보입니다. 없을 경우 `nil`입니다.
        var limit: Limit?

        /// 새로운 차트 데이터를 초기화합니다.
        ///
        /// - Parameters:
        ///   - elements: 바 차트에 표시할 막대 요소 목록입니다.
        ///   - limit: 기준선 정보입니다. 기본값은 `nil`입니다.
        init(
            elements: [Element],
            limit: Limit? = nil
        ) {
            self.elements = elements
            self.limit = limit
        }
    }
}
