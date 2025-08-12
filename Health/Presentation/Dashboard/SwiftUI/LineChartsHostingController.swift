//
//  LineChartsHostingController.swift
//  Health
//
//  Created by 김건우 on 8/6/25.
//

import SwiftUI
import UIKit

final class LineChartsHostingController: UIHostingController<LineChartsView> {

    private(set) var chartsData: [HKData]

    init(chartsData: [HKData]) {
        self.chartsData = chartsData

        super.init(rootView: LineChartsView(chartsData: chartsData))
    }
    
    @MainActor @preconcurrency required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
