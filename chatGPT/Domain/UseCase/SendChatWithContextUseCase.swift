//
//  SendChatWithContextUseCase.swift
//  chatGPT
//
//  Created by Codex on 2024.
//

import Foundation

final class SendChatWithContextUseCase {
    private let openAIRepository: OpenAIRepository
    private let contextRepository: ChatContextRepository
    private let summarizeUseCase: SummarizeMessagesUseCase
    private let maxHistory: Int
    private let summaryTrigger: Int

    init(openAIRepository: OpenAIRepository,
         contextRepository: ChatContextRepository,
         summarizeUseCase: SummarizeMessagesUseCase,
         maxHistory: Int = 10,
         summaryTrigger: Int = 20) {
        self.openAIRepository = openAIRepository
        self.contextRepository = contextRepository
        self.summarizeUseCase = summarizeUseCase
        self.maxHistory = maxHistory
        self.summaryTrigger = summaryTrigger
    }

    func execute(prompt: String, model: OpenAIModel, stream: Bool, completion: @escaping (Result<String, Error>) -> Void) {
        var messages = [Message]()
        if let summary = contextRepository.summary {
            messages.append(Message(role: .system, content: summary))
        }
        messages += contextRepository.messages
        messages.append(Message(role: .user, content: prompt))

        openAIRepository.sendChat(messages: messages, model: model, stream: stream) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let reply):
                self.contextRepository.append(role: .user, content: prompt)
                self.contextRepository.append(role: .assistant, content: reply)
                self.contextRepository.trim(to: self.maxHistory)
                completion(.success(reply))
                self.summarizeIfNeeded(model: model)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func clearContext() {
        contextRepository.clear()
    }

    private func summarizeIfNeeded(model: OpenAIModel) {
        let count = contextRepository.messages.count
        guard count > summaryTrigger else { return }
        let history = contextRepository.messages
        summarizeUseCase.execute(messages: history, model: model) { [weak self] result in
            switch result {
            case .success(let summary):
                self?.contextRepository.updateSummary(summary)
                self?.contextRepository.trim(to: self?.maxHistory ?? 10)
            case .failure:
                break
            }
        }
    }
}
