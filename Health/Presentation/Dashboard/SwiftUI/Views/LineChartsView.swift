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
        Chart(chartsData, id: \.endDate) { data in
            LineMark(
                x: .value("date", data.endDate.description),
                y: .value("value", data.value)
            )
            .foregroundStyle(.gray)
            .symbol(.circle)
            .symbolSize(25)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .background(Color(uiColor: .boxBg))
    }
}

#Preview(traits: .fixedLayout(width: 300, height: 200)) {
    let datas: [HKData] = (0..<7).map { index in
        let date = Date.now.addingTimeInterval(TimeInterval(-index * 86_400))
        let (startDay, endDay) = date.rangeOfDay()
        return HKData(startDate: startDay, endDate: endDay, value: Double.random(in: 0..<1000))
    }

    LineChartsView(chartsData: datas)
        .padding()
}
