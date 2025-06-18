//
//  ChatContextRepositoryImpl.swift
//  chatGPT
//
//  Created by Codex on 2024.
//

import Foundation

final class ChatContextRepositoryImpl: ChatContextRepository {
    private var storedMessages: [Message] = []
    private(set) var summary: String?

    var messages: [Message] {
        storedMessages
    }

    func append(role: RoleType, content: String) {
        storedMessages.append(Message(role: role, content: content))
    }

    func updateSummary(_ summary: String) {
        self.summary = summary
    }

    func trim(to maxCount: Int) {
        if storedMessages.count > maxCount {
            storedMessages = Array(storedMessages.suffix(maxCount))
        }
    }

    func clear() {
        storedMessages.removeAll()
        summary = nil
    }
}
