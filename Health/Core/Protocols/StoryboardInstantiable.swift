//
//  StoryboardInstantiable.swift
//  Health
//
//  Created by 김건우 on 7/31/25.
//

import UIKit

///
protocol StoryboardInstantiable {

    ///
    static func storyboard(name: String?) -> UIStoryboard
}

extension StoryboardInstantiable where Self: UIViewController {


    /// <#Description#>
    static var storyboardName: String {
        NSStringFromClass(Self.self)
            .components(separatedBy: ".")
            .last!
    }


    /// <#Description#>
    /// - Parameter name: <#name description#>
    /// - Returns: <#description#>
    static func storyboard(name: String? = nil) -> UIStoryboard {
        let bundle = Bundle(for: Self.self)
        return UIStoryboard(name: name ?? storyboardName, bundle: bundle)
    }


    /// <#Description#>
    /// - Parameters:
    ///   - name: <#name description#>
    ///   - identifier: <#identifier description#>
    /// - Returns: <#description#>
    static func instantiateIntialViewController(name: String? = nil) -> Self {
        guard let vc = storyboard(name: name).instantiateInitialViewController() as? Self
        else { fatalError("could not load \(Self.self)") }
        return vc
    }
}
