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

    private var chartsData: [HealthKitData]

    init(chartsData: [HealthKitData]) {
        self.chartsData = chartsData
    }

    var body: some View {
        Chart(chartsData, id: \.endDate) { data in
            LineMark(
                x: .value("date", data.endDate.description),
                y: .value("value", data.value)
            )
            .foregroundStyle(.accent)
            .lineStyle(.init(lineWidth: 3.25))
            .symbol(.circle)
            .symbolSize(150)
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}

#Preview(traits: .fixedLayout(width: 300, height: 200)) {
    let datas: [HealthKitData] = (0..<7).map { index in
        let date = Date.now.addingTimeInterval(TimeInterval(-index * 86_400))
        let (startDay, endDay) = date.rangeOfDay()
        return (startDay, endDay, Double.random(in: 0..<1000))
    }

    LineChartsView(chartsData: datas)
        .padding()
}
