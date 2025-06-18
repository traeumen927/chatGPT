//
//  SummarizeMessagesUseCase.swift
//  chatGPT
//
//  Created by Codex on 2024.
//

import Foundation

final class SummarizeMessagesUseCase {
    private let repository: OpenAIRepository
    private let maxRetry: Int

    init(repository: OpenAIRepository, maxRetry: Int = 2) {
        self.repository = repository
        self.maxRetry = maxRetry
    }

    func execute(messages: [Message], model: OpenAIModel, retry: Int = 0, completion: @escaping (Result<String, Error>) -> Void) {
        let text = messages.map { "\($0.role.rawValue): \($0.content)" }.joined(separator: "\n")
        let prompt = "다음 대화를 간단히 요약해 줘.\n" + text
        let reqMessages = [Message(role: .system, content: prompt)]
        repository.sendChat(messages: reqMessages, model: model) { [weak self] result in
            switch result {
            case .success(let summary):
                completion(.success(summary))
            case .failure(let error):
                if retry < (self?.maxRetry ?? 0) {
                    self?.execute(messages: messages, model: model, retry: retry + 1, completion: completion)
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
}
