//
//  OpenAIModel.swift
//  chatGPT
//
//  Created by 홍정연 on 6/16/25.
//

import Foundation

enum OpenAIModel: String, CaseIterable {
    case gpt35 = "gpt-3.5-turbo"
    case gpt4 = "gpt-4"
    case gpt4o = "gpt-4o"
    
    var isStreamingSupported: Bool {
        return true
    }
    
    var displayName: String {
        switch self {
        case .gpt35: return "GPT-3.5"
        case .gpt4: return "GPT-4"
        case .gpt4o: return "GPT-4o"
        }
    }
}

// MARK: UserDefaults를 활용한 chatGPT model 저장
struct ModelPreference {
    private static let key = "selectedChatModel"
    
    static var current: OpenAIModel {
        get {
            if let raw = UserDefaults.standard.string(forKey: key),
               let model = OpenAIModel(rawValue: raw) {
                return model
            }
            return .gpt35
        }
        set {
            UserDefaults.standard.setValue(newValue.rawValue, forKey: key)
        }
    }
}
