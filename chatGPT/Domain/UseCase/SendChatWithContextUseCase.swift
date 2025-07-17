//
//  SendChatWithContextUseCase.swift
//  chatGPT
//
//  Created by Codex on 2024.
//

import Foundation
import RxSwift

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

    func execute(prompt: String,
                 model: OpenAIModel,
                 stream: Bool,
                 preference: String?,
                 images: [Data] = [],
                 files: [Data] = [],
                 completion: @escaping (Result<String, Error>) -> Void) {
        var messages = [Message]()
        if let preference {
            messages.append(Message(role: .system, content: preference))
        }
        if let summary = contextRepository.summary {
            messages.append(Message(role: .system, content: summary))
        }
        messages += contextRepository.messages
        if images.isEmpty && files.isEmpty {
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
            return
        }

        var visionMessages = messages.map { VisionMessage(role: $0.role, content: [.init(type: "text", text: $0.content, imageURL: nil)]) }
        var contents: [VisionContent] = [.init(type: "text", text: prompt, imageURL: nil)]
        images.forEach { data in
            let b64 = data.base64EncodedString()
            contents.append(VisionContent(type: "image_url", text: nil, imageURL: "data:image/jpeg;base64,\(b64)"))
        }
        files.forEach { data in
            let b64 = data.base64EncodedString()
            contents.append(VisionContent(type: "image_url", text: nil, imageURL: "data:application/pdf;base64,\(b64)"))
        }
        visionMessages.append(VisionMessage(role: .user, content: contents))

        openAIRepository.sendVision(messages: visionMessages, model: model, stream: stream) { [weak self] result in
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

    func stream(prompt: String,
                model: OpenAIModel,
                preference: String?,
                images: [Data] = [],
                files: [Data] = []) -> Observable<String> {
        var messages = [Message]()
        if let preference {
            messages.append(Message(role: .system, content: preference))
        }
        if let summary = contextRepository.summary {
            messages.append(Message(role: .system, content: summary))
        }
        messages += contextRepository.messages
        if images.isEmpty && files.isEmpty {
            messages.append(Message(role: .user, content: prompt))
            return openAIRepository.sendChatStream(messages: messages, model: model)
        }

        var visionMessages = messages.map { VisionMessage(role: $0.role, content: [.init(type: "text", text: $0.content, imageURL: nil)]) }
        var contents: [VisionContent] = [.init(type: "text", text: prompt, imageURL: nil)]
        images.forEach { data in
            let b64 = data.base64EncodedString()
            contents.append(VisionContent(type: "image_url", text: nil, imageURL: "data:image/jpeg;base64,\(b64)"))
        }
        files.forEach { data in
            let b64 = data.base64EncodedString()
            contents.append(VisionContent(type: "image_url", text: nil, imageURL: "data:application/pdf;base64,\(b64)"))
        }
        visionMessages.append(VisionMessage(role: .user, content: contents))

        return openAIRepository.sendVisionStream(messages: visionMessages, model: model)
    }

    func finalize(prompt: String, reply: String, model: OpenAIModel) {
        contextRepository.append(role: .user, content: prompt)
        contextRepository.append(role: .assistant, content: reply)
        contextRepository.trim(to: maxHistory)
        summarizeIfNeeded(model: model)
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
