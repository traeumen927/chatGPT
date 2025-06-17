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

    func execute(prompt: String, model: OpenAIModel, completion: @escaping (Result<String, Error>) -> Void) {
        repository.sendChat(prompt: prompt, model: model, completion: completion)
    }
}
