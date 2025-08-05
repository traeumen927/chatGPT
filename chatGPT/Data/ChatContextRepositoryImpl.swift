//
//  ChatContextRepositoryImpl.swift
//  chatGPT
//
//  Created by Codex on 2024.
//

import Foundation

// MARK: 채팅 문맥 저장 구현체

final class ChatContextRepositoryImpl: ChatContextRepository {
    private let messagesKey = "chatContextMessages"
    private let summaryKey = "chatContextSummary"
    private let userDefaults: UserDefaults

    private var storedMessages: [Message] = []
    private(set) var summary: String?

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let data = userDefaults.data(forKey: messagesKey),
           let messages = try? JSONDecoder().decode([Message].self, from: data) {
            self.storedMessages = messages
        }
        self.summary = userDefaults.string(forKey: summaryKey)
    }

    var messages: [Message] {
        storedMessages
    }

    func append(role: RoleType, content: String) {
        storedMessages.append(Message(role: role, content: content))
        save()
    }

    func updateSummary(_ summary: String) {
        self.summary = summary
        save()
    }

    func replace(messages: [Message], summary: String?) {
        self.storedMessages = messages
        self.summary = summary
        save()
    }

    func trim(to maxCount: Int) {
        if storedMessages.count > maxCount {
            storedMessages = Array(storedMessages.suffix(maxCount))
            save()
        }
    }

    func clear() {
        storedMessages.removeAll()
        summary = nil
        save()
    }

    private func save() {
        let data = try? JSONEncoder().encode(storedMessages)
        userDefaults.set(data, forKey: messagesKey)
        if let summary {
            userDefaults.set(summary, forKey: summaryKey)
        } else {
            userDefaults.removeObject(forKey: summaryKey)
        }
    }
}
