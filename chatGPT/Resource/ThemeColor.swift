//
//  ThemeColor.swift
//  chatGPT
//
//  Created by 홍정연 on 6/11/25.
//

import UIKit

struct ThemeColor {
    static var tintPrimary: UIColor {
        .dynamic(light: .white, dark: .white)
    }
    static var tintSecondary: UIColor {
        .dynamic(light: .white, dark: UIColor(hex: "#D1D1D1"))
    }
    static var tintTertiary: UIColor {
        .dynamic(light: .white, dark: UIColor(hex: "#989898"))
    }
    static var tintDisable: UIColor {
        .dynamic(light: UIColor(hex: "#313239"), dark: .darkGray)
    }
    static var tintDark: UIColor {
        .dynamic(light: UIColor(hex: "#0F0F0F"), dark: .white)
    }
    static var label1: UIColor {
        .dynamic(light: UIColor(hex: "#2D2D2D"), dark: .white)
    }
    static var label2: UIColor {
        .dynamic(light: UIColor(hex: "#939393"), dark: UIColor(hex: "#A0A0A0"))
    }
    static var label3: UIColor {
        .dynamic(light: UIColor(hex: "#EFEFEF"), dark: UIColor(hex: "#1F1F1F"))
    }
    static var background1: UIColor {
        .dynamic(light: .white, dark: .black)
    }
    static var background2: UIColor {
        .dynamic(light: UIColor(hex: "#FBFAFA"), dark: UIColor(hex: "#1D1D1D"))
    }
    static var background3: UIColor {
        .dynamic(light: UIColor(hex: "#DEE2E6"), dark: UIColor(hex: "#2C2C2E"))
    }
    static var positive: UIColor {
        .dynamic(light: UIColor(hex: "#1261C4"), dark: UIColor(hex: "#0A84FF"))
    }
    static var negative: UIColor {
        .dynamic(light: UIColor(hex: "#C84A31"), dark: UIColor(hex: "#FF453A"))
    }
    static var inlineCodeForeground: UIColor {
        .dynamic(light: UIColor(hex: "#ff6b6b"), dark: UIColor(hex: "#a80000"))
    }
    static var inlineCodeBackground: UIColor {
        .dynamic(light: UIColor(hex: "#e5e5e5"), dark: UIColor(hex: "#8e9196"))
    }
}
