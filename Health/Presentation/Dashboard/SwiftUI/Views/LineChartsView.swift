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
    
    // TOOD: - LineCharts가 범용 데이터를 받도록 코드 리팩토링하기
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

#Preview(traits: .fixedLayout(width: 300, height: 200)) {
    let chartsData: [HKData] = (0..<7).map { index in
        let date = Date.now.addingDays(-index)!
        let (startDate, endDate) = date.rangeOfDay()
        return HKData(startDate: startDate, endDate: endDate, value: Double.random(in: 1..<1000))
    }

    LineChartsView(chartsData: chartsData)
        .padding()
}
