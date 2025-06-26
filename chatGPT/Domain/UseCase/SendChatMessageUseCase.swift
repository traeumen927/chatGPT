//
//  SendChatMessageUseCase.swift
//  chatGPT
//
//  Created by 홍정연 on 6/17/25.
//

import Foundation

final class SendChatMessageUseCase {
    private let repository: OpenAIRepository

    init(repository: OpenAIRepository) {
        self.repository = repository
    }

    func execute(messages: [Message], model: OpenAIModel, stream: Bool, completion: @escaping (Result<String, Error>) -> Void) {
        repository.sendChat(messages: messages, model: model, stream: stream, completion: completion)
    }
}
