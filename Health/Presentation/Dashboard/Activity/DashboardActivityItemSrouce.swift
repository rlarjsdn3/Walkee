//
//  DashboardActivityItemSrouce.swift
//  Health
//
//  Created by 김건우 on 8/24/25.
//

import UIKit
import LinkPresentation

final class DashboardActivityItemSrouce: NSObject, UIActivityItemSource {

    private let date: Date
    private let title: String
    private let image: UIImage

    init(
        date: Date = .now,
        title: String,
        image: UIImage
    ) {
        self.date = date
        self.title = title
        self.image = image
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        image
    }
    
    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        image
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = "나의 건강 대시보드 (\(date.formatted(using: .md)))"
        metadata.imageProvider = NSItemProvider(object: image)
        return metadata
    }
}
