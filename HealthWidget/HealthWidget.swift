//
//  HealthWidget.swift
//  HealthWidget
//
//  Created by Seohyun Kim on 8/23/25.
//

import SwiftUI
import WidgetKit
/// 위젯 타임라인에 공급할 **건강 대시보드 스냅샷**을 제공하는 Provider.
///
/// - Note: `SharedStore.loadDashboard()`로 App Group에 저장된 스냅샷을 읽고,
/// 없으면 `.empty`를 사용한다. 메인 앱이 적절한 시점에
/// `WidgetCenter.shared.reloadTimelines(ofKind:)`를 호출하면 즉시 갱신된다.
/// - SeeAlso: ``DashEntry``
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
	
	/// 위젯을 주기적으로 업데이트하기 위한 **타임라인**을 구성한다.
	///
	/// - Parameters:
	/// - context: 렌더링 컨텍스트
	/// - completion: 타임라인(엔트리 배열 + 정책)을 전달하는 완료 핸들러
	/// - Returns: `completion`을 통해 타임라인을 전달한다.
	/// - Note: 정책은 `.after(next)`로 설정되어 **약 45분 주기**로 갱신된다.
	/// 주기 외에도 메인 앱의 `reloadTimelines` 호출 시 즉시 갱신된다.
	func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
		let snap = SharedStore.loadDashboard() ?? .empty
		// 주기 갱신(예: 45분 뒤) — 앱이 수시로 reloadTimelines를 쏘면 그때 즉시 갱신됨
		let next = Calendar.current.date(byAdding: .minute, value: 45, to: .now)!
		completion(Timeline(entries: [Entry(date: .now, snap: snap)], policy: .after(next)))
	}
}
/// 위젯이 표시할 **단일 시점의 데이터 스냅샷**.
///
/// - Parameters:
/// - date: 타임라인 기준 시각
/// - snap: 대시보드 수치(걸음·거리·운동시간·활동에너지·목표 등)
/// - SeeAlso: ``Provider``
struct DashEntry: TimelineEntry {
	/// 타임라인 갱신 시각
	let date: Date
	/// 건강 대시보드 스냅샷
	let snap: HealthDashboardSnapshot
}
/// 걸음 및 건강 지표를 렌더링하는 **Widget 엔트리 포인트**.
///
/// - Note: 현재 `.systemMedium` 패밀리만 지원한다.
/// - Important: **투명 배경**을 위해 `.containerBackground(.clear, for: .widget)` 적용.
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
