//
//  ChatViewModel.swift
//  chatGPT
//
//  Created by 홍정연 on 6/17/25.
//

import Foundation
import RxSwift
import RxRelay

final class ChatViewModel {
    enum MessageType {
        case user
        case assistant
        case error
    }

    struct ChatMessage: Hashable, Identifiable {
        let id = UUID()
        let type: MessageType
        let text: String
    }

    // MARK: - Output
    let messages = BehaviorRelay<[ChatMessage]>(value: [])

    // MARK: - Dependencies
    private let sendMessageUseCase: SendChatWithContextUseCase
    private let disposeBag = DisposeBag()

    init(sendMessageUseCase: SendChatWithContextUseCase) {
        self.sendMessageUseCase = sendMessageUseCase
    }

    func send(prompt: String, model: OpenAIModel) {
        appendMessage(ChatMessage(type: .user, text: prompt))

        sendMessageUseCase.execute(prompt: prompt, model: model) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let reply):
                self.appendMessage(ChatMessage(type: .assistant, text: reply))

            case .failure(let error):
                let message = (error as? OpenAIError)?.errorMessage ?? error.localizedDescription
                self.appendMessage(ChatMessage(type: .error, text: message))
            }
        }
    }

    private func appendMessage(_ message: ChatMessage) {
        var current = messages.value
        current.append(message)
        messages.accept(current)
    }
}
