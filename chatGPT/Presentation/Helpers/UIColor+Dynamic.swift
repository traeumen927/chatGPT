import UIKit

extension UIColor {
    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { trait in
                trait.userInterfaceStyle == .dark ? dark : light
            }
        } else {
            return light
        }
    }
}
