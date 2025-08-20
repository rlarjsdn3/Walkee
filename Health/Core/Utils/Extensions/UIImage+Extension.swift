//
//  UIImage+Extension.swift
//  Health
//
//  Created by 김건우 on 8/20/25.
//

import UIKit

extension UIImage {

    /// 지정한 너비에 맞게 이미지 크기를 비율 유지하여 조정합니다.
    /// - Parameter width: 새로 조정할 이미지의 너비
    /// - Returns: 크기가 조정된 `UIImage` 또는 실패 시 `nil`
    func resized(width: CGFloat) -> UIImage? {
        let ratio = width / self.size.width
        let height = self.size.height * ratio
        let newSize = CGSize(width: width, height: height)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
