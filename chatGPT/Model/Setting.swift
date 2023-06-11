//
//  Setting.swift
//  chatGPT
//
//  Created by 홍정연 on 2023/06/07.
//

import Foundation

class Setting {
    
    private let defaults = UserDefaults.standard
    private let modelKey = "modelKey"
    private let hapticKey = "haptic"
    private let streamKey = "streamKey"
    
    class var shared: Setting {
        struct Static {
            static let instance = Setting()
        }
        
        return Static.instance
    }
    
    var model: String {
        set{
            defaults.setValue(newValue, forKey: modelKey)
        }
        get {
            return defaults.string(forKey: modelKey) ?? "gpt-3.5-turbo"
        }
    }
    
    var haptic: Bool {
        set{
            defaults.setValue(newValue, forKey: hapticKey)
        }
        get {
            return defaults.bool(forKey: hapticKey)
        }
    }
    
    var stream: Bool {
        set{
            defaults.setValue(newValue, forKey: streamKey)
        }
        get {
            return defaults.bool(forKey: streamKey)
        }
    }
}






enum OptionType {
    case normalCell(model: OptionNormal)
    case switchCell(model: OptionSwitch)
}

struct Section {
    let title: String
    let options: [OptionType]
}


struct OptionSwitch {
    let title: String
    let systemImage: String
    let handler: ((Bool) -> Void)
    var isOn: Bool
}

struct OptionNormal {
    let title: String
    let systemImage: String
    let handler: (() -> Void)
    let subTitle: String?
}

struct OptionSelect {
    let title: String
    let systemImage: String
    let handler: (() -> Void)
    let options: [String]
}


