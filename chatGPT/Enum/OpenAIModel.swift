//
//  OpenAIModel.swift
//  chatGPT
//
//  Created by 홍정연 on 6/16/25.
//

import Foundation

struct OpenAIModel: Equatable, Hashable {
    let id: String

    var displayName: String {
        return id
    }
}


// MARK: UserDefaults를 활용한 chatGPT model 저장
struct ModelPreference {
    private static let key = "selectedChatModel"

    static var current: OpenAIModel {
        if let id = UserDefaults.standard.string(forKey: key) {
            return OpenAIModel(id: id)
        }
        return OpenAIModel(id: "unknown")
    }

    static var currentId: String? {
        UserDefaults.standard.string(forKey: key)
    }

    static func save(_ model: OpenAIModel) {
        UserDefaults.standard.set(model.id, forKey: key)
    }
}
