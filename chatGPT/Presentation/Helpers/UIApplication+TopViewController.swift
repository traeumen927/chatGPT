//
//  UIApplication+TopViewController.swift
//  chatGPT
//
//  Created by 홍정연 on 7/15/25.
//

import UIKit

extension UIApplication {
    static var topViewController: UIViewController? {
        guard let scene = shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        return topViewController(base: root)
    }

    private static func topViewController(base: UIViewController) -> UIViewController {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController ?? nav)
        }
        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController ?? tab)
        }
        if let presented = base.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
