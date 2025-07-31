//
//  StoryboardInstantiable.swift
//  Health
//
//  Created by 김건우 on 7/31/25.
//

import UIKit

/// 스토리보드에서 인스턴스를 생성할 수 있도록 하는 프로토콜입니다.
protocol StoryboardInstantiable {

    /// 주어진 이름의 스토리보드를 반환합니다.
    ///
    /// - Parameter name: 스토리보드 이름입니다. `nil`일 경우 기본 이름(`storyboardName`)이 사용됩니다.
    /// - Returns: `UIStoryboard` 인스턴스를 반환합니다.
    static func storyboard(name: String?) -> UIStoryboard
}

@MainActor
extension StoryboardInstantiable where Self: UIViewController {

    /// 기본 스토리보드 이름입니다.
    ///
    /// 클래스 이름을 기준으로 자동 생성되며, 모듈명을 제외한 클래스 이름이 사용됩니다.
    static var storyboardName: String {
        NSStringFromClass(Self.self)
            .components(separatedBy: ".")
            .last!
    }

    /// 주어진 이름 또는 기본 이름을 사용해 스토리보드를 생성합니다.
    ///
    /// - Parameter name: 스토리보드 이름입니다. `nil`일 경우 `storyboardName`이 사용됩니다.
    /// - Returns: 해당 이름의 `UIStoryboard` 인스턴스를 반환합니다.
    static func storyboard(name: String? = nil) -> UIStoryboard {
        let bundle = Bundle(for: Self.self)
        return UIStoryboard(name: name ?? storyboardName, bundle: bundle)
    }

    /// 스토리보드로부터 초기 뷰 컨트롤러를 인스턴스화합니다.
    ///
    /// - Parameter name: 사용할 스토리보드 이름입니다. `nil`일 경우 `storyboardName`이 사용됩니다.
    /// - Returns: 초기 뷰 컨트롤러로 지정된 `Self` 타입 인스턴스를 반환합니다.
    /// - Note: 초기 뷰 컨트롤러가 존재하지 않거나 형변환에 실패할 경우 앱이 종료됩니다.
    static func instantiateInitialViewController(name: String? = nil) -> Self {
        guard let vc = storyboard(name: name).instantiateInitialViewController() as? Self
        else { fatalError("could not load \(Self.self)") }
        return vc
    }
}
