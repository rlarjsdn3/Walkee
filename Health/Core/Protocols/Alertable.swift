//
//  Alertable.swift
//  Health
//
//  Created by 김건우 on 7/31/25.
//

import UIKit

import TSAlertController

/// 사용자에게 알림창(Alert)을 표시하는 기능을 제공합니다.
protocol Alertable { }

@MainActor
extension Alertable where Self: UIViewController {

    /// 확인 및 취소 버튼이 포함된 커스텀 알림창을 표시합니다.
    ///
    /// 이 메서드는 `TSAlertController`를 이용해 제목, 메시지, 액션 핸들러 등을 설정하고,
    /// 시각적 전환 효과 및 스타일을 함께 지정합니다.
    ///
    /// - Parameters:
    ///   - title: 알림창의 제목입니다.
    ///   - message: 알림창에 표시할 부가 설명 메시지입니다. 기본값은 `nil`입니다.
    ///   - onPrimaryAction: 확인 버튼이 눌렸을 때 실행할 핸들러입니다.
    ///   - onCancelAction: 취소 버튼이 눌렸을 때 실행할 핸들러입니다. 설정하지 않으면 취소 버튼이 표시되지 않습니다.
    func showAlert(
        _ title: String,
        message: String? = nil,
        onPrimaryAction: @escaping TSAlertActionHandler,
        onCancelAction: TSAlertActionHandler? = nil
    ) {
        let alert = TSAlertController(
            title: title,
            message: message,
            options: [.dismissOnSwipeDown, .interactiveScaleAndDrag],
            preferredStyle: .alert
        )
        alert.configuration.enteringTransition = .slideUp
        alert.configuration.exitingTransition = .slideDown
        alert.configuration.headerAnimation = .slideUp
        alert.configuration.buttonGroupAnimation = .slideUp
        alert.viewConfiguration.backgroundBorderColor = UIColor.systemGray4.cgColor
        alert.viewConfiguration.backgroundBorderWidth = 1

        let primaryAction = TSAlertAction(
            title: "확인",
            style: .default,
            handler: onPrimaryAction
        )
        primaryAction.configuration.titleAttributes = [.font: UIFont.preferredFont(forTextStyle: .headline),
                                                       .foregroundColor: UIColor.white]
        primaryAction.configuration.backgroundColor = UIColor.systemBlue // TODO: - 강조 색상으로 수정하기
        alert.addAction(primaryAction)

        if let onCancelAction = onCancelAction {
            let cancelAction = TSAlertAction(
                title: "취소",
                style: .cancel,
                handler: onCancelAction
            )
            alert.addAction(cancelAction)
        }

        self.present(alert, animated: true)
    }

    /// 사용자의 중요한 작업(예: 삭제)을 확인받기 위한 알림창을 표시합니다.
    ///
    /// 이 메서드는 삭제 등의 위험한 작업을 수행하기 전에 사용자에게 확인을 요청하는 용도로 사용됩니다.
    /// 붉은색 테두리와 버튼 스타일로 시각적으로 위험성을 강조합니다.
    ///
    /// - Parameters:
    ///   - title: 알림창의 제목입니다.
    ///   - message: 알림창에 표시할 부가 설명 메시지입니다. 기본값은 `nil`입니다.
    ///   - onDeleteAction: 삭제 버튼이 눌렸을 때 실행할 핸들러입니다.
    ///   - onCancelAction: 취소 버튼이 눌렸을 때 실행할 핸들러입니다.
    func showDestructiveAlert(
        _ title: String,
        message: String? = nil,
        onDeleteAction: @escaping TSAlertActionHandler,
        onCancelAction: @escaping TSAlertActionHandler
    ) {
        let alert = TSAlertController(
            title: title,
            message: message,
            options: [.dismissOnSwipeDown, .interactiveScaleAndDrag],
            preferredStyle: .alert
        )
        alert.configuration.enteringTransition = .slideUp
        alert.configuration.exitingTransition = .slideDown
        alert.configuration.headerAnimation = .slideUp
        alert.configuration.buttonGroupAnimation = .slideUp
        alert.viewConfiguration.backgroundBorderColor = UIColor.systemGray4.cgColor
        alert.viewConfiguration.backgroundBorderWidth = 1

        let deleteAction = TSAlertAction(
            title: "삭제",
            style: .destructive,
            handler: onDeleteAction
        )
        deleteAction.configuration.backgroundColor = UIColor.systemRed
        deleteAction.configuration.titleAttributes = [.font: UIFont.preferredFont(forTextStyle: .headline),
                                                      .foregroundColor: UIColor.white]
        alert.addAction(deleteAction)

        let cancelAction = TSAlertAction(
            title: "취소",
            style: .cancel,
            handler: onCancelAction
        )
        alert.addAction(cancelAction)

        self.present(alert, animated: true)
    }
    
    /// 하단에서 떠오르는 시트 형태의 알림창(Floating Sheet)을 표시합니다.
    ///
    /// 여러 개의 사용자 정의 액션을 포함할 수 있으며, 인터랙티브한 제스처로 닫을 수 있는 경고창입니다.
    ///
    /// - Parameters:
    ///   - title: 알림창의 제목입니다.
    ///   - message: 알림창에 표시할 부가 설명 메시지입니다. 기본값은 `nil`입니다.
    ///   - actions: 알림창에 추가할 사용자 정의 액션 목록입니다.
    func showFloatingSheet(
        _ title: String,
        message: String? = nil,
        actions: [TSAlertAction]
    ) {
        let alert = TSAlertController(
            title: title,
            message: message,
            options: [.dismissOnSwipeDown, .interactiveScaleAndDrag],
            preferredStyle: .floatingSheet
        )
        alert.viewConfiguration.backgroundBorderColor = UIColor.systemGray4.cgColor
        alert.viewConfiguration.backgroundBorderWidth = 1

        actions.forEach { action in alert.addAction(action) }

        self.present(alert, animated: true)
    }
    
    /// 지정한 커스텀 뷰를 포함한 플로팅 시트(Floating Sheet) 형태의 알림창을 표시합니다.
    ///
    /// 사용자 정의 뷰를 알림창의 본문으로 삽입할 수 있으며, 추가적으로 여러 개의 액션 버튼도 설정할 수 있습니다.
    ///
    /// - Parameters:
    ///   - uiview: 알림창에 표시할 사용자 정의 `UIView`입니다.
    ///   - actions: 알림창에 추가할 사용자 정의 액션 목록입니다.
    func showFloatingSheet(
        _ uiview: UIView,
        actions: [TSAlertAction]
    ) {
        let alert = TSAlertController(
            uiview,
            options: [.dismissOnSwipeDown, .interactiveScaleAndDrag],
            preferredStyle: .floatingSheet
        )
        alert.viewConfiguration.backgroundBorderColor = UIColor.systemGray4.cgColor
        alert.viewConfiguration.backgroundBorderWidth = 1

        actions.forEach { action in alert.addAction(action) }

        self.present(alert, animated: true)
    }
}
