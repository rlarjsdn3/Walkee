//
//  HealthWidget.swift
//  HealthWidget
//
//  Created by Nat Kim on 8/23/25.
//

import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
	typealias Entry = DashEntry

	func placeholder(in context: Context) -> Entry { Entry(date: .now, snap: .previewMock) }
	func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) { completion(.init(date: .now, snap: SharedStore.loadDashboard() ?? .previewMock)) }
	func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
		let s = SharedStore.loadDashboard() ?? .previewMock
		completion(Timeline(entries: [Entry(date: .now, snap: s)], policy: .atEnd))
	}
}

struct DashEntry: TimelineEntry {
    let date: Date
    //let configuration: ConfigurationAppIntent
	let snap: HealthDashboardSnapshot
}


@main
struct HealthWidget: Widget {
	var body: some WidgetConfiguration {
		StaticConfiguration(kind: "HealthWidget",
							provider: Provider()) { entry in
			HealthDashboardMediumView(snapShot: entry.snap)
				.containerBackground(.clear, for: .widget)
		}
		.configurationDisplayName("건강 대시보드")
		.description("걸음/거리/운동/에너지 위젯")
		.supportedFamilies([.systemMedium])
		.contentMarginsDisabled()
	}
}

#Preview("Medium", as: .systemMedium, widget: {
	HealthWidget()
}, timeline: {
	DashEntry(date: .now, snap: .previewMock)
})
