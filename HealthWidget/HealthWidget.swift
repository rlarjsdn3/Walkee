//
//  HealthWidget.swift
//  HealthWidget
//
//  Created by Seohyun Kim on 8/23/25.
//

import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
	typealias Entry = DashEntry

	func placeholder(in context: Context) -> Entry { Entry(date: .now, snap: .previewMock) }
	
	/// 런타임 스냅샷
	/// - Parameters:
	///   - context: <#context description#>
	///   - completion: <#completion description#>
	func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
		let snap = SharedStore.loadDashboard() ?? .empty
		completion(Entry(date: .now, snap: snap))
	}
	
	/// 런타임 타임라인 - App Group에서 읽고, 없으면 `.empty`
	/// - Parameters:
	///   - context: <#context description#>
	///   - completion: <#completion description#>
	func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
		let snap = SharedStore.loadDashboard() ?? .empty
		// 주기 갱신(예: 45분 뒤) — 앱이 수시로 reloadTimelines를 쏘면 그때 즉시 갱신됨
		let next = Calendar.current.date(byAdding: .minute, value: 45, to: .now)!
		completion(Timeline(entries: [Entry(date: .now, snap: snap)], policy: .after(next)))
	}
}

struct DashEntry: TimelineEntry {
    let date: Date
    //let configuration: ConfigurationAppIntent
	let snap: HealthDashboardSnapshot
}


@main
struct HealthWidget: Widget {
	static let kind = WidgetIDs.health
	var body: some WidgetConfiguration {
		StaticConfiguration(kind: Self.kind,
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
