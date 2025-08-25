//
//  HealthWidget.swift
//  HealthWidget
//
//  Created by Seohyun Kim on 8/23/25.
//

import SwiftUI
import WidgetKit

///  위젯에 필요한 데이터를 공급하는 타임라인 프로바이더
struct Provider: TimelineProvider {
	typealias Entry = DashEntry
	
	///  위젯이 초기 로딩될 때 표시할 플레이스홀더 데이터 반환
	func placeholder(in context: Context) -> Entry { Entry(date: .now, snap: .empty) }
	
	/// 위젯 미리보기나 위젯 갤러리에서 사용할 스냅샷 데이터 반환
	/// - Parameters:
	///   - context: 위젯 렌더링 컨텍스트
	///   - completion: 스냅샷 데이터를 전달하는 완료 핸들러
	func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
		let snap = SharedStore.loadDashboard() ?? .empty
		completion(Entry(date: .now, snap: snap))
	}
	
	/// 주기적으로 위젯을 업데이트하기 위한 타임라인 반환
	/// App Group에서 대시보드 데이터를 읽고, 없으면 `.empty`를 사용
	/// - Parameters:
	///   - context: 위젯 렌더링 컨텍스트
	///   - completion: 타임라인을 전달하는 완료 핸들러
	func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
		let snap = SharedStore.loadDashboard() ?? .empty
		// 주기 갱신(예: 45분 뒤) — 앱이 수시로 reloadTimelines를 쏘면 그때 즉시 갱신됨
		let next = Calendar.current.date(byAdding: .minute, value: 45, to: .now)!
		completion(Timeline(entries: [Entry(date: .now, snap: snap)], policy: .after(next)))
	}
}

/// 위젯이 사용할 타임라인 엔트리
/// 한 시점의 데이터 스냅샷을 나타냄
struct DashEntry: TimelineEntry {
	/// 타임라인 갱신 시각
	let date: Date
	/// 건강 대시보드 스냅샷
	let snap: HealthDashboardSnapshot
}

/// 걸음 및 건강 데이터를 표시하는 위젯 엔트리 포인트
@main
struct HealthWidget: Widget {
	static let kind = WidgetIDs.health
	
	var body: some WidgetConfiguration {
		StaticConfiguration(kind: Self.kind, provider: Provider()) { entry in
			HealthDashboardMediumView(snapShot: entry.snap)
				.containerBackground(.clear, for: .widget)
		}
		.configurationDisplayName("걸음 대시보드")
		.description("실시간 걸음 수와 건강 데이터를 확인하세요.")
		.supportedFamilies([.systemMedium])
		.contentMarginsDisabled()
	}
}

#Preview("Medium", as: .systemMedium, widget: {
	HealthWidget()
}, timeline: {
	DashEntry(date: .now, snap: .previewMock)
})
