//
//  ChatViewModel.swift
//  chatGPT
//
//  Created by 홍정연 on 6/17/25.
//

import Foundation
import RxSwift

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
    let conversationIDSubject = PublishSubject<String>()
    var conversationIDObservable: Observable<String> {
        conversationIDSubject.asObservable()
    }

    // MARK: - Dependencies
    private let sendMessageUseCase: SendChatWithContextUseCase
    private let summarizeUseCase: SummarizeMessagesUseCase
    private let saveConversationUseCase: SaveConversationUseCase
    private let appendMessageUseCase: AppendMessageUseCase
    private let disposeBag = DisposeBag()

    private var conversationID: String?

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
        let isFirst = conversationID == nil

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
                if let id = self.conversationID {
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
                if let id = self.conversationID {
                    self.appendMessageUseCase.execute(conversationID: id,
                                                     role: .error,
                                                     text: message)
                        .subscribe()
                        .disposed(by: self.disposeBag)
                }
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
                        self?.conversationID = id
                        self?.conversationIDSubject.onNext(id)
                    })
                    .disposed(by: self.disposeBag)
            }
        }
    }
}
