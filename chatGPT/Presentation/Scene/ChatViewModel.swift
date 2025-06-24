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
    private let summarizeUseCase: SummarizeMessagesUseCase
    private let saveConversationUseCase: SaveConversationUseCase
    private let appendMessageUseCase: AppendMessageUseCase
    private let disposeBag = DisposeBag()

    private let conversationIDRelay = BehaviorRelay<String?>(value: nil)
    var conversationID: String? { conversationIDRelay.value }
    var conversationIDObservable: Observable<String?> { conversationIDRelay.asObservable() }

    init(sendMessageUseCase: SendChatWithContextUseCase,
         summarizeUseCase: SummarizeMessagesUseCase,
         saveConversationUseCase: SaveConversationUseCase,
         appendMessageUseCase: AppendMessageUseCase) {
        self.sendMessageUseCase = sendMessageUseCase
        self.summarizeUseCase = summarizeUseCase
        self.saveConversationUseCase = saveConversationUseCase
        self.appendMessageUseCase = appendMessageUseCase
    }

    func send(prompt: String, model: OpenAIModel) {
        let isFirst = messages.value.isEmpty
        appendMessage(ChatMessage(type: .user, text: prompt))

        if let id = conversationID {
            appendMessageUseCase.execute(conversationID: id,
                                        role: .user,
                                        text: prompt)
                .subscribe()
                .disposed(by: disposeBag)
        }

        sendMessageUseCase.execute(prompt: prompt, model: model) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let reply):
                self.appendMessage(ChatMessage(type: .assistant, text: reply))
                if let id = self.conversationID, !isFirst {
                    self.appendMessageUseCase.execute(conversationID: id,
                                                     role: .assistant,
                                                     text: reply)
                        .subscribe()
                        .disposed(by: self.disposeBag)
                }
                if isFirst {
                    self.saveFirstConversation(question: prompt, answer: reply, model: model)
                }

            case .failure(let error):
                let message = (error as? OpenAIError)?.errorMessage ?? error.localizedDescription
                self.appendMessage(ChatMessage(type: .error, text: message))
            }
        }
    }

    private func saveFirstConversation(question: String, answer: String, model: OpenAIModel) {
        let history = [
            Message(role: .user, content: question),
            Message(role: .assistant, content: answer)
        ]

        summarizeUseCase.execute(messages: history, model: model) { [weak self] result in
            guard let self = self else { return }
            if case .success(let title) = result {
                self.saveConversationUseCase.execute(title: title, question: question, answer: answer)
                    .subscribe(onSuccess: { [weak self] id in
                        self?.conversationIDRelay.accept(id)
                    })
                    .disposed(by: self.disposeBag)
            }
        }
    }

    private func appendMessage(_ message: ChatMessage) {
        var current = messages.value
        current.append(message)
        messages.accept(current)
    }
}
