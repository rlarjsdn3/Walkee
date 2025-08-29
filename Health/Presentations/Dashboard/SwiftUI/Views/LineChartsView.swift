//
//  LineChartsView.swift
//  Health
//
//  Created by 김건우 on 8/6/25.
//

import Charts
import HealthKit
import SwiftUI

struct LineChartsView: View {

    private var chartsData: [HKData]

    init(chartsData: [HKData]) {
        self.chartsData = chartsData
    }

    var body: some View {
        Chart(chartsData, id: \.startDate) { data in
            LineMark(
                x: .value("date", data.startDate.description),
                y: .value("value", data.value)
            )
            .foregroundStyle(.gray)
            .symbol(symbol: {
                ZStack {
                    if data.startDate.isEqual(with: .now.startOfDay()) {
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundStyle(.accent)
                    } else {
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundStyle(.gray)
                    }

                    Circle()
                        .frame(width: 4, height: 4)
                        .foregroundStyle(.appOffWhite)
                }
            })
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .background(Color(uiColor: .boxBg))
    }
}
