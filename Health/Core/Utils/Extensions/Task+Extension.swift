//
//  Task+Extension.swift
//  Health
//
//  Created by 김건우 on 8/19/25.
//

import Foundation

extension Task where Failure == Error {

    /// 일정 시간 지연 후 비동기 작업을 실행하는 유틸리티 메서드입니다.
    ///
    /// - Parameters:
    ///   - seconds: 작업을 지연할 시간(초 단위)입니다.
    ///   - priority: 생성할 `Task`의 우선순위입니다. 기본값은 `.medium`입니다.
    ///   - operation: 지연 이후 실행할 비동기 작업 클로저입니다.
    /// - Returns: 지정된 시간만큼 지연 후 주어진 작업을 실행하는 `Task` 인스턴스를 반환합니다.
    ///
    /// - Note: `Task.sleep(for:)`를 사용하여 현재 태스크를 일시 정지한 뒤,
    ///         주어진 작업을 실행합니다.
    @discardableResult
    static func delay(
        for seconds: Double,
        priority: TaskPriority = .medium,
        @_implicitSelfCapture operation: @Sendable @escaping () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            try await Task<Never, Never>.sleep(for: .seconds(seconds))
            return try await operation()
        }
    }
}
