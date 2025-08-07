//
//  NSCollectionLayoutEnvironment+Extension.swift
//  Health
//
//  Created by 김건우 on 8/7/25.
//

import UIKit

extension NSCollectionLayoutEnvironment {
    
    /// 현재 환경의 세로 크기 클래스에 따라 반환할 레이아웃 크기를 선택합니다.
    ///
    /// - Parameters:
    ///   - compact: 세로 크기 클래스가 `.compact` 또는 `.unspecified`인 경우 반환할 크기입니다.
    ///   - regular: 세로 크기 클래스가 `.regular`인 경우 반환할 크기입니다.
    /// - Returns: 현재 환경에 맞는 `NSCollectionLayoutDimension`을 반환합니다.
    func verticalSizeClass(
        compact: @autoclosure () -> NSCollectionLayoutDimension,
        regular: @autoclosure () -> NSCollectionLayoutDimension
    ) -> NSCollectionLayoutDimension {
        switch traitCollection.verticalSizeClass {
        case .unspecified, .compact: return compact()
        case .regular:               return regular()
        @unknown default:            return regular()
        }
    }

    /// 현재 환경의 가로 크기 클래스에 따라 값을 선택합니다.
    ///
    /// - Parameters:
    ///   - compact: 가로 크기 클래스가 `.compact` 또는 `.unspecified`인 경우 반환할 값입니다.
    ///   - regular: 가로 크기 클래스가 `.regular`인 경우 반환할 값입니다.
    /// - Returns: 현재 환경에 맞는 값을 반환합니다.
    func horizontalSizeClass<Value>(
        compact: @autoclosure () -> Value,
        regular: @autoclosure () -> Value
    ) -> Value {
        switch traitCollection.horizontalSizeClass {
        case .unspecified, .compact: return compact()
        case .regular:               return regular()
        @unknown default:            return regular()
        }
    }

    /// 현재 디바이스의 레이아웃 환경 및 방향에 따라 값을 선택합니다.
    ///
    /// - Parameters:
    ///   - iphonePortrait: iPhone 세로 방향에서 사용할 값입니다.
    ///   - ipadPortrait: iPad 세로 방향에서 사용할 값입니다.
    ///   - ipadLandscape: iPad 가로 방향에서 사용할 값입니다. (※ 현재 미사용)
    /// - Returns: 현재 환경에 맞는 값을 반환합니다.
    ///
    /// - Note: iPad의 경우 세로/가로 방향을 구분하여 처리하며, 그 외에는 기본적으로 iPhone 세로 방향 기준으로 반환합니다.
    func orientation<Value>(
        iphonePortrait: @autoclosure () -> Value,
        ipadPortrait: @autoclosure () -> Value,
        ipadLandscape: @autoclosure () -> Value
    ) -> Value {
        let sizeClasses = (traitCollection.verticalSizeClass,
                           traitCollection.horizontalSizeClass)
        switch sizeClasses {
        case (.compact, .regular): // iPhone 세로 방향
            return iphonePortrait()
        case (.regular, .regular): // iPad
            if UIApplication.shared.isPortrait { return ipadPortrait() }
            else { return iphonePortrait() } // 현재는 iPad 가로 방향을 구분하지 않음
        default:
            return iphonePortrait()
        }
    }
}

fileprivate extension UIApplication {
    
    /// 현재 앱의 키 윈도우가 세로 방향인지 여부를 반환합니다.
    var isPortrait: Bool {
        for scene in connectedScenes {
            guard let windowScene = scene as? UIWindowScene
            else { continue }
            
            if windowScene.windows.isEmpty {
                continue
            }
            
            if let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
                return keyWindow.windowScene?.interfaceOrientation.isPortrait ?? false
            }
        }
        return false
    }
}
