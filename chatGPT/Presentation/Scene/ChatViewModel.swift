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
    private let chatUseCase: ChatUseCase
    private var chatID: String?
    private let disposeBag = DisposeBag()

    init(sendMessageUseCase: SendChatWithContextUseCase, chatUseCase: ChatUseCase) {
        self.sendMessageUseCase = sendMessageUseCase
        self.chatUseCase = chatUseCase
    }

    func send(prompt: String, model: OpenAIModel) {
        let userMessage = ChatRecordMessage(id: UUID().uuidString,
                                            text: prompt,
                                            isUser: true,
                                            createdAt: Date())
        appendMessage(ChatMessage(type: .user, text: prompt))

        if let id = chatID {
            chatUseCase.appendMessage(chatID: id, message: userMessage)
                .subscribe()
                .disposed(by: disposeBag)
        } else {
            chatUseCase.createChat(title: prompt)
                .flatMap { [weak self] chat -> Observable<Void> in
                    self?.chatID = chat.id
                    return self?.chatUseCase.appendMessage(chatID: chat.id, message: userMessage) ?? .empty()
                }
                .subscribe()
                .disposed(by: disposeBag)
        }

        sendMessageUseCase.execute(prompt: prompt, model: model) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let reply):
                self.appendMessage(ChatMessage(type: .assistant, text: reply))
                if let id = self.chatID {
                    let msg = ChatRecordMessage(id: UUID().uuidString,
                                                text: reply,
                                                isUser: false,
                                                createdAt: Date())
                    self.chatUseCase.appendMessage(chatID: id, message: msg)
                        .subscribe()
                        .disposed(by: self.disposeBag)
                }

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
