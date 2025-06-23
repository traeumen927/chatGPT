//
//  UIImage.swift
//  chatGPT
//
//  Created by 홍정연 on 6/23/25.
//

import UIKit

extension UIImage {
    /// 이미지 크기 조정
    func resize(to targetSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0)
        self.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage ?? self
    }

    /// 모서리를 둥글게 처리한 이미지 반환
    func withRoundedCorners(radius: CGFloat) -> UIImage {
        let rect = CGRect(origin: .zero, size: self.size)

        UIGraphicsBeginImageContextWithOptions(self.size, false, 0)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        path.addClip()
        self.draw(in: rect)
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return roundedImage ?? self
    }
}
