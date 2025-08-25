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

    /// 사용자에게 알림창을 표시합니다.
    ///
    /// 지정한 제목과 메시지, 기본 및 취소 버튼을 포함한 `TSAlertController`를 생성하여
    /// 현재 뷰 컨트롤러 위에 모달로 표시합니다.
    ///
    /// - Note: 아이패드 환경에서는 알림창의 너비가 고정적으로 300pt로 설정됩니다.
    ///
    /// - Parameters:
    ///   - title: 알림창에 표시할 제목 문자열.
    ///   - message: 알림창에 표시할 부가 메시지 문자열. 기본값은 `nil`입니다.
    ///   - primaryTitle: 기본 버튼에 표시할 제목 문자열. 기본값은 `"확인"`입니다.
    ///   - onPrimaryAction: 기본 버튼을 탭했을 때 실행할 핸들러 클로저.
    ///   - cancelTitle: 취소 버튼에 표시할 제목 문자열. 기본값은 `"취소"`입니다.
    ///   - onCancelAction: 취소 버튼을 탭했을 때 실행할 핸들러 클로저. 기본값은 `nil`입니다.
    ///   - viewConfiguration: 알림창 뷰의 레이아웃 및 스타일 구성을 지정하는 객체. 전달하지 않으면 기본 설정이 적용됩니다.
    ///   - configuration: 알림창의 동작 및 속성을 정의하는 구성 객체. 전달하지 않으면 기본 설정이 적용됩니다.
    func showAlert(
        _ title: String,
        message: String? = nil,
        primaryTitle: String = "확인",
        onPrimaryAction: @escaping TSAlertActionHandler,
        cancelTitle: String = "취소",
        onCancelAction: TSAlertActionHandler? = nil,
        viewConfiguration: TSAlertController.ViewConfiguration? = nil,
        configuration: TSAlertController.Configuration? = nil
    ) {
        let alert = TSAlertController(
            title: title,
            message: message,
            options: [.dismissOnSwipeDown, .interactiveScaleAndDrag, .dismissOnTapOutside],
            preferredStyle: .alert
        )

        alert.configuration = configuration ?? defaultAlertConfiguration
        alert.viewConfiguration = viewConfiguration ?? defaultAlertViewConfiguration

        sizeClasses(vRhR: {
            alert.viewConfiguration.size.width = .flexible(minimum: 300, maximum: 300)
        })

        let primaryAction = TSAlertAction(
            title: primaryTitle,
            style: .default,
            handler: onPrimaryAction
        )
        primaryAction.highlightType = .fadeIn
        primaryAction.configuration.titleAttributes = [.font: UIFont.preferredFont(forTextStyle: .headline),
                                                       .foregroundColor: UIColor.systemBackground]
        primaryAction.configuration.backgroundColor = .accent
        alert.addAction(primaryAction)

        if let onCancelAction = onCancelAction {
            let cancelAction = TSAlertAction(
                title: cancelTitle,
                style: .cancel,
                handler: onCancelAction
            )
            cancelAction.highlightType = .fadeIn
            alert.addAction(cancelAction)
        }

        self.present(alert, animated: true)
    }

    /// 사용자에게 삭제 동작을 포함한 알림창을 표시합니다.
    ///
    /// 지정한 제목과 메시지를 표시하고, 기본적으로 삭제 버튼과 취소 버튼을 제공합니다.
    /// 삭제 버튼은 `.destructive` 스타일로 표시되며 빨간색 배경과 강조된 텍스트 스타일이 적용됩니다.
    ///
    /// - Note: 아이패드 환경에서는 알림창의 너비가 고정적으로 300pt로 설정됩니다.
    ///
    /// - Parameters:
    ///   - title: 알림창에 표시할 제목 문자열.
    ///   - message: 알림창에 표시할 부가 메시지 문자열. 기본값은 `nil`입니다.
    ///   - deleteTitle: 삭제 버튼에 표시할 제목 문자열. 기본값은 `"삭제"`입니다.
    ///   - onDeleteAction: 삭제 버튼을 탭했을 때 실행할 핸들러 클로저.
    ///   - cancelTitle: 취소 버튼에 표시할 제목 문자열. 기본값은 `"취소"`입니다.
    ///   - onCancelAction: 취소 버튼을 탭했을 때 실행할 핸들러 클로저.
    ///   - viewConfiguration: 알림창 뷰의 레이아웃 및 스타일 구성을 지정하는 객체. 전달하지 않으면 기본 설정이 적용됩니다.
    ///   - configuration: 알림창의 동작 및 속성을 정의하는 구성 객체. 전달하지 않으면 기본 설정이 적용됩니다.
    func showDestructiveAlert(
        _ title: String,
        message: String? = nil,
        deleteTitle: String = "삭제",
        onDeleteAction: @escaping TSAlertActionHandler,
        cancelTitle: String = "취소",
        onCancelAction: @escaping TSAlertActionHandler,
        viewConfiguration: TSAlertController.ViewConfiguration? = nil,
        configuration: TSAlertController.Configuration? = nil
    ) {
        let alert = TSAlertController(
            title: title,
            message: message,
            options: [.dismissOnSwipeDown, .interactiveScaleAndDrag, .dismissOnTapOutside],
            preferredStyle: .alert
        )

        alert.configuration = configuration ?? defaultAlertConfiguration
        alert.viewConfiguration = viewConfiguration ?? defaultAlertViewConfiguration

        sizeClasses(vRhR: {
            alert.viewConfiguration.size.width = .flexible(minimum: 300, maximum: 300)
        })
        
        let deleteAction = TSAlertAction(
            title: deleteTitle,
            style: .destructive,
            handler: onDeleteAction
        )
        deleteAction.highlightType = .fadeIn
        deleteAction.configuration.backgroundColor = UIColor.systemRed
        deleteAction.configuration.titleAttributes = [.font: UIFont.preferredFont(forTextStyle: .headline),
                                                      .foregroundColor: UIColor.systemBackground]
        alert.addAction(deleteAction)

        let cancelAction = TSAlertAction(
            title: cancelTitle,
            style: .cancel,
            handler: onCancelAction
        )
        cancelAction.highlightType = .fadeIn
        alert.addAction(cancelAction)

        self.present(alert, animated: true)
    }
    
    /// 사용자에게 플로팅 시트 스타일의 알림창을 표시합니다.
    ///
    /// 지정한 제목과 메시지를 표시하고, 기본적으로 확인 버튼과 선택적으로 취소 버튼을 제공합니다.
    /// 알림창은 `.floatingSheet` 스타일로 표시되며, 드래그·스와이프·외부 탭을 통한 해제가 가능합니다.
    ///
    /// - Note: 아이패드 환경에서는 플로팅 시트의 너비가 500pt로 고정됩니다.
    ///
    /// - Parameters:
    ///   - title: 알림창에 표시할 제목 문자열.
    ///   - message: 알림창에 표시할 부가 메시지 문자열. 기본값은 `nil`입니다.
    ///   - confirmTitle: 확인 버튼에 표시할 제목 문자열. 기본값은 `"확인"`입니다.
    ///   - onConfirmAction: 확인 버튼을 탭했을 때 실행할 핸들러 클로저.
    ///   - cancelTitle: 취소 버튼에 표시할 제목 문자열. 기본값은 `"취소"`입니다.
    ///   - onCancelAction: 취소 버튼을 탭했을 때 실행할 핸들러 클로저. 기본값은 `nil`입니다.
    ///   - viewConfiguration: 알림창 뷰의 레이아웃 및 스타일 구성을 지정하는 객체. 전달하지 않으면 기본 설정이 적용됩니다.
    ///   - configuration: 알림창의 동작 및 속성을 정의하는 구성 객체. 전달하지 않으면 기본 설정이 적용됩니다.
    func showFloatingSheet(
        _ title: String,
        message: String? = nil,
        confirmTitle: String = "확인",
        onConfirmAction: @escaping TSAlertActionHandler,
        cancelTitle: String = "취소",
        onCancelAction: TSAlertActionHandler? = nil,
        viewConfiguration: TSAlertController.ViewConfiguration? = nil,
        configuration: TSAlertController.Configuration? = nil,
    ) {
        let alert = TSAlertController(
            title: title,
            message: message,
            options: [.dismissOnSwipeDown, .interactiveScaleAndDrag, .dismissOnTapOutside],
            preferredStyle: .floatingSheet
        )

        if let configuration { alert.configuration = configuration }
        if let viewConfiguration { alert.viewConfiguration = viewConfiguration }

        sizeClasses(vRhR: {
            alert.viewConfiguration.size.width = .flexible(minimum: 500, maximum: 500)
        })

        let confirmAction = TSAlertAction(
            title: confirmTitle,
            style: .default,
            handler: onConfirmAction
        )
        confirmAction.highlightType = .fadeIn
        confirmAction.configuration.backgroundColor = .accent
        confirmAction.configuration.titleAttributes = [.font: UIFont.preferredFont(forTextStyle: .headline),
                                                       .foregroundColor: UIColor.systemBackground]
        alert.addAction(confirmAction)

        if let onCancelAction = onCancelAction {
            let cancelAction = TSAlertAction(
                title: cancelTitle,
                style: .cancel,
                handler: onCancelAction
            )
            cancelAction.highlightType = .fadeIn
            alert.addAction(cancelAction)
        }

        self.present(alert, animated: true)
    }
    
    /// 사용자 정의 뷰를 포함한 플로팅 시트를 표시합니다.
    ///
    /// 전달된 `UIView`를 콘텐츠로 사용하여 플로팅 시트를 생성하고,
    /// 확인 및 취소 버튼을 함께 표시합니다.
    /// 사용자는 드래그, 스와이프, 외부 탭을 통해 시트를 닫을 수 있습니다.
    ///
    /// - Note: 아이패드 환경에서는 플로팅 시트의 너비가 500pt로 고정됩니다.
    ///
    /// - Parameters:
    ///   - uiview: 플로팅 시트 내부에 표시할 사용자 정의 뷰.
    ///   - confirmTitle: 확인 버튼에 표시할 제목 문자열. 기본값은 `"확인"`입니다.
    ///   - onConfirmAction: 확인 버튼을 탭했을 때 실행할 핸들러 클로저.
    ///   - cancelTitle: 취소 버튼에 표시할 제목 문자열. 기본값은 `"취소"`입니다.
    ///   - onCancelAction: 취소 버튼을 탭했을 때 실행할 핸들러 클로저. 기본값은 `nil`입니다.
    ///   - viewConfiguration: 알림창 뷰의 레이아웃 및 스타일 구성을 지정하는 객체. 전달하지 않으면 기본 설정이 적용됩니다.
    ///   - configuration: 알림창의 동작 및 속성을 정의하는 구성 객체. 전달하지 않으면 기본 설정이 적용됩니다.
    func showFloatingSheet(
        _ uiview: UIView,
        confirmTitle: String = "확인",
        onConfirmAction: @escaping TSAlertActionHandler,
        cancelTitle: String = "취소",
        onCancelAction: TSAlertActionHandler? = nil,
        viewConfiguration: TSAlertController.ViewConfiguration? = nil,
        configuration: TSAlertController.Configuration? = nil,
    ) {
        let alert = TSAlertController(
            uiview,
            options: [.dismissOnSwipeDown, .interactiveScaleAndDrag, .dismissOnTapOutside],
            preferredStyle: .floatingSheet
        )

        if let configuration { alert.configuration = configuration }
        if let viewConfiguration { alert.viewConfiguration = viewConfiguration }

        sizeClasses(vRhR: {
            alert.viewConfiguration.size.width = .flexible(minimum: 500, maximum: 500)
        })

        let confirmAction = TSAlertAction(
            title: confirmTitle,
            style: .default,
            handler: onConfirmAction
        )
        confirmAction.highlightType = .fadeIn
        confirmAction.configuration.backgroundColor = .accent
        confirmAction.configuration.titleAttributes = [.font: UIFont.preferredFont(forTextStyle: .headline),
                                                       .foregroundColor: UIColor.systemBackground]
        alert.addAction(confirmAction)

        if let onCancelAction = onCancelAction {
            let cancelAction = TSAlertAction(
                title: cancelTitle,
                style: .cancel,
                handler: onCancelAction
            )
            cancelAction.highlightType = .fadeIn
            alert.addAction(cancelAction)
        }
        
        self.present(alert, animated: true)
    }
    


    /// 사용자 정의 뷰를 포함한 액션 시트를 표시합니다.
    ///
    /// 전달한 `UIView`를 콘텐츠로 사용하여 `.actionSheet` 스타일로 표시합니다.
    /// 드래그·스와이프·외부 탭으로 닫을 수 있으며, 늘어나는 드래그 효과(`.stretchyDragging`)가 적용됩니다.
    ///
    /// - Note: 아이패드 환경에서는 액션 시트의 너비가 500pt로 고정됩니다.
    ///
    /// - Parameters:
    ///   - uiview: 액션 시트 내부에 표시할 사용자 정의 뷰.
    ///   - confirmTitle: 확인 버튼에 표시할 제목. 기본값은 `"확인"`입니다.
    ///   - onConfirmAction: 확인 버튼 탭 시 호출될 핸들러.
    ///   - cancelTitle: 취소 버튼에 표시할 제목. 기본값은 `"취소"`입니다.
    ///   - onCancelAction: 취소 버튼 탭 시 호출될 핸들러. 기본값은 `nil`입니다.
    ///   - viewConfiguration: 뷰 레이아웃/스타일 구성. 전달하지 않으면 기본 설정이 적용됩니다.
    ///   - configuration: 동작 및 속성 구성. 전달하지 않으면 기본 설정이 적용됩니다.
    func showActionSheet(
        _ uiview: UIView,
        confirmTitle: String = "확인",
        onConfirmAction: @escaping TSAlertActionHandler,
        cancelTitle: String = "취소",
        onCancelAction: TSAlertActionHandler? = nil,
        viewConfiguration: TSAlertController.ViewConfiguration? = nil,
        configuration: TSAlertController.Configuration? = nil,
    ) {
        let alert = TSAlertController(
            uiview,
            options: [.dismissOnSwipeDown, .interactiveScaleAndDrag, .dismissOnTapOutside, .stretchyDragging],
            preferredStyle: .actionSheet
        )

        if let configuration { alert.configuration = configuration }
        if let viewConfiguration { alert.viewConfiguration = viewConfiguration }

        sizeClasses(vRhR: {
            alert.viewConfiguration.size.width = .flexible(minimum: 500, maximum: 500)
        })

        let confirmAction = TSAlertAction(
            title: confirmTitle,
            style: .default,
            handler: onConfirmAction
        )
        confirmAction.highlightType = .fadeIn
        confirmAction.configuration.backgroundColor = .accent
        confirmAction.configuration.titleAttributes = [.font: UIFont.preferredFont(forTextStyle: .headline),
                                                       .foregroundColor: UIColor.systemBackground]
        alert.addAction(confirmAction)

        if let onCancelAction = onCancelAction {
            let cancelAction = TSAlertAction(
                title: cancelTitle,
                style: .cancel,
                handler: onCancelAction
            )
            cancelAction.highlightType = .fadeIn
            alert.addAction(cancelAction)
        }

        self.present(alert, animated: true)
    }
    
    func showActionSheetForProfile(
        buildView: () -> UIView,
        heightRatio: CGFloat = 0.4,
        widthRatio: CGFloat = 1.0,
        iPadLandscapeHeightRatio: CGFloat = 0.4,
        iPadLandscapeWidthRatio: CGFloat = 0.8,
        onConfirm: ((UIView) -> Void)? = nil
    ) {
        let contentView = buildView()
        
        let alert = TSAlertController(
            contentView,
            options: [.interactiveScaleAndDrag, .dismissOnTapOutside],
            preferredStyle: .actionSheet
        )
        
        alert.configuration.prefersGrabberVisible = false
        alert.configuration.enteringTransition = .slideUp
        alert.configuration.exitingTransition = .slideDown
        alert.configuration.headerAnimation = .slideUp
        alert.configuration.buttonGroupAnimation = .slideUp
        alert.viewConfiguration.spacing.keyboardSpacing = 100
                
        let isPad = (traitCollection.userInterfaceIdiom == .pad)

        let isLandscape: Bool = {
            if let iface = view.window?.windowScene?.interfaceOrientation {
                return iface.isLandscape
            }
            if UIDevice.current.orientation.isValidInterfaceOrientation {
                return UIDevice.current.orientation.isLandscape
            }
            // 최후 폴백
            return UIScreen.main.bounds.width > UIScreen.main.bounds.height
        }()

        let isPadLandscape = isPad && isLandscape

        let appliedHeightRatio = isPadLandscape ? iPadLandscapeHeightRatio : heightRatio
        let appliedWidthRatio  = isPadLandscape ? iPadLandscapeWidthRatio : widthRatio
        
        alert.viewConfiguration.size.width  = .proportional(minimumRatio: appliedWidthRatio,
                                                            maximumRatio: appliedWidthRatio)
        alert.viewConfiguration.size.height = .proportional(minimumRatio: appliedHeightRatio,
                                                            maximumRatio: appliedHeightRatio)
        
        let confirmAction = TSAlertAction(title: "확인", style: .default) { _ in
            onConfirm?(contentView)
        }
        confirmAction.configuration.backgroundColor = .accent
        confirmAction.configuration.titleAttributes = [
            .font: UIFont.preferredFont(forTextStyle: .headline),
            .foregroundColor: UIColor.systemBackground
        ]
        confirmAction.highlightType = .fadeIn
        alert.addAction(confirmAction)
        
        
        self.present(alert, animated: true)
    }
}


fileprivate extension Alertable {

    var defaultAlertConfiguration: TSAlertController.Configuration {
        var config = TSAlertController.Configuration()
        config.enteringTransition = .slideUp
        config.exitingTransition = .slideDown
        config.headerAnimation = .slideUp
        config.buttonGroupAnimation = .slideUp
        return config
    }

    var defaultAlertViewConfiguration: TSAlertController.ViewConfiguration {
        var config = TSAlertController.ViewConfiguration()
        config.titleAlignment = .center
        config.messageAlignment = .center
        return config
    }
}
