//
//  HealthNavigationBarItem.swift
//  Health
//
//  Created by 김건우 on 8/20/25.
//

import UIKit

/// 커스텀 내비게이션 바에서 사용되는 버튼 아이템을 나타내는 구조체입니다.
struct HealthBarButtonItem {

    /// 버튼에 표시할 제목입니다.
    /// - Note: `nil`일 경우 제목은 표시되지 않습니다.
    var title: String?

    /// 버튼에 표시할 이미지입니다.
    /// - Note: `nil`일 경우 이미지는 표시되지 않습니다.
    var image: UIImage?

    /// 버튼이 탭되었을 때 실행될 기본 동작입니다.
    /// - Note: 설정되지 않은 경우 버튼을 탭해도 동작하지 않습니다.
    var primaryAction: (() -> Void)?

    /// 버튼 아이템을 초기화합니다.
    /// - Parameters:
    ///   - title: 버튼에 표시할 제목 (옵션)
    ///   - image: 버튼에 표시할 이미지 (옵션)
    ///   - primaryAction: 버튼이 탭되었을 때 실행할 동작 (옵션)
    init(
        title: String? = nil,
        image: UIImage? = nil,
        primaryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.image = image
        self.primaryAction = primaryAction
    }
}
