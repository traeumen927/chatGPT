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
    let conversationChanged = PublishRelay<Void>()

    // MARK: - Dependencies
    private let sendMessageUseCase: SendChatWithContextUseCase
    private let summarizeUseCase: SummarizeMessagesUseCase
    private let saveConversationUseCase: SaveConversationUseCase
    private let appendMessageUseCase: AppendMessageUseCase
    private let fetchMessagesUseCase: FetchConversationMessagesUseCase
    private let contextRepository: ChatContextRepository
    private let disposeBag = DisposeBag()

    private var draftMessages: [ChatMessage]? = nil

    var hasDraft: Bool { draftMessages != nil }

    private let conversationIDRelay = BehaviorRelay<String?>(value: nil)
    var conversationID: String? { conversationIDRelay.value }
    var conversationIDObservable: Observable<String?> { conversationIDRelay.asObservable() }

    init(sendMessageUseCase: SendChatWithContextUseCase,
         summarizeUseCase: SummarizeMessagesUseCase,
         saveConversationUseCase: SaveConversationUseCase,
         appendMessageUseCase: AppendMessageUseCase,
         fetchMessagesUseCase: FetchConversationMessagesUseCase,
         contextRepository: ChatContextRepository) {
        self.sendMessageUseCase = sendMessageUseCase
        self.summarizeUseCase = summarizeUseCase
        self.saveConversationUseCase = saveConversationUseCase
        self.appendMessageUseCase = appendMessageUseCase
        self.fetchMessagesUseCase = fetchMessagesUseCase
        self.contextRepository = contextRepository
    }

    func send(prompt: String, model: OpenAIModel, stream: Bool) {
        let isFirst = messages.value.isEmpty
        appendMessage(ChatMessage(type: .user, text: prompt))

        if let id = conversationID {
            appendMessageUseCase.execute(conversationID: id,
                                        role: .user,
                                        text: prompt)
                .subscribe()
                .disposed(by: disposeBag)
        }

        sendMessageUseCase.execute(prompt: prompt, model: model, stream: stream) { [weak self] result in
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
                let cleanTitle = title.removingQuotes()
                self.saveConversationUseCase.execute(title: cleanTitle, question: question, answer: answer)
                    .subscribe(onSuccess: { [weak self] id in
                        self?.conversationIDRelay.accept(id)
                        self?.draftMessages = nil
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

    func startNewConversation() {
        conversationChanged.accept(())
        draftMessages = []
        messages.accept([])
        conversationIDRelay.accept(nil)
        sendMessageUseCase.clearContext()
    }

    func resumeDraftConversation() {
        conversationChanged.accept(())
        messages.accept(draftMessages ?? [])
        conversationIDRelay.accept(nil)
        sendMessageUseCase.clearContext()
    }

    func loadConversation(id: String) {
        if conversationID == nil {
            draftMessages = messages.value
        }
        fetchMessagesUseCase.execute(conversationID: id)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] list in
                guard let self else { return }
                let chatMessages = list.map { item in
                    ChatMessage(type: item.role == .user ? .user : .assistant, text: item.text)
                }
                self.conversationChanged.accept(())
                self.messages.accept(chatMessages)
                self.conversationIDRelay.accept(id)
                let msgs = list.map { Message(role: $0.role, content: $0.text) }
                self.contextRepository.replace(messages: msgs, summary: nil)
            })
            .disposed(by: disposeBag)
    }
}
