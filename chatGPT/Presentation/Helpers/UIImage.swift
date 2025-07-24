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
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1)
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

    /// DALL·E 편집용 규격에 맞는 PNG 데이터 반환
    func pngForImageEdit(targetSize: CGSize) -> Data? {
        let aspect = min(targetSize.width / size.width, targetSize.height / size.height)
        let newSize = CGSize(width: size.width * aspect, height: size.height * aspect)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1)
        UIColor.clear.setFill()
        UIRectFill(CGRect(origin: .zero, size: targetSize))
        draw(in: CGRect(
            x: (targetSize.width - newSize.width) / 2,
            y: (targetSize.height - newSize.height) / 2,
            width: newSize.width,
            height: newSize.height
        ))
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img?.pngData()
    }

    /// 전체 영역 편집을 위한 투명 마스크 PNG 데이터 반환
    static func fullEditMask(size: CGSize) -> Data? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        UIColor.clear.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img?.pngData()
    }
}
