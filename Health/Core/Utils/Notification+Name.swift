//
//  Notification+Name.swift
//  Health
//
//  Created by 김건우 on 8/22/25.
//

import Foundation

extension Notification.Name {

    /// 프로필 화면에서 `목표 걸음 수` 데이터가 갱신되었음을 알리는 알림 이름입니다.
    static let didUpdateGoalStepCount = Notification.Name("didUpdateGoalStepCount")

    /// 프로필 화면에서 `Apple 건강 앱` 연동 스위치 상태가 갱신되었음을 알리는 알림 이름입니다.
    static let didChangeHealthLinkStatusOnProfile = Notification.Name("didChangeHealthLinkStatusOnProfile")

    /// 걸음 수 데이터 동기화가 완료되었을 때 발송되는 알림
    ///
    /// 이 알림은 `DefaultStepSyncService.syncSteps()` 메서드가 성공적으로 완료된 후
    /// 메인 스레드에서 발송됩니다. UI를 업데이트하거나 추가 작업을 트리거하는 데 사용할 수 있습니다.
    static let didSyncStepData = Notification.Name("didSyncStepData")

    /// HealthKit 권한 상태가 변경되었음을 알리는 알림 이름입니다.
    ///
    /// `userInfo[.status]` 값이 `true`라면 필요한 데이터 읽기가 하나라도 허용된 상태를 의미합니다.
    /// `false`라면 하나 이상의 권한이 부족하여 일부 데이터를 읽을 수 없음을 의미합니다.
    /// 최초 앱 실행 시에는 전달되지 않으며, 앱 내부 또는 외부에서 권한 상태가 실제로 변경되었을 때만 게시됩니다.
    static let didChangeHKSharingAuthorizationStatus = Notification.Name("didChangeHKAuthorizationStatus")
	
	static let sseParseDidRecord = Notification.Name("SSEParseDidRecord")
}
