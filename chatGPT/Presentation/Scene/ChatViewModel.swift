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
    
    final class ChatMessage: Hashable, Identifiable {
        let id: UUID
        var type: MessageType
        var text: String

        init(id: UUID = UUID(), type: MessageType, text: String) {
            self.id = id
            self.type = type
            self.text = text
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    // MARK: - Output
    let messages = BehaviorRelay<[ChatMessage]>(value: [])
    let conversationChanged = PublishRelay<Void>()
    private let streamingMessageRelay = PublishRelay<ChatMessage>()
    var streamingMessage: Observable<ChatMessage> { streamingMessageRelay.asObservable() }
    
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
        
        guard stream else {
            sendMessageUseCase.execute(prompt: prompt, model: model, stream: false) { [weak self] result in
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
            return
        }
        
        let assistantID = UUID()
        appendMessage(ChatMessage(id: assistantID, type: .assistant, text: ""))
        var fullText = ""
        
        sendMessageUseCase.stream(prompt: prompt, model: model)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] chunk in
                guard let self else { return }
                fullText += chunk
                self.updateMessage(id: assistantID, text: fullText)
            }, onError: { [weak self] error in
                let message = (error as? OpenAIError)?.errorMessage ?? error.localizedDescription
                self?.updateMessage(id: assistantID, text: message, type: .error)
            }, onCompleted: { [weak self] in
                guard let self else { return }
                self.sendMessageUseCase.finalize(prompt: prompt, reply: fullText, model: model)
                if let id = self.conversationID, !isFirst {
                    self.appendMessageUseCase.execute(conversationID: id,
                                                      role: .assistant,
                                                      text: fullText)
                    .subscribe()
                    .disposed(by: self.disposeBag)
                }
                if isFirst {
                    self.saveFirstConversation(question: prompt, answer: fullText, model: model)
                }
            })
            .disposed(by: disposeBag)
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
    
    private func updateMessage(id: UUID, text: String, type: MessageType? = nil) {
        guard let index = messages.value.firstIndex(where: { $0.id == id }) else { return }
        let message = messages.value[index]
        message.text = text
        if let type = type { message.type = type }
        streamingMessageRelay.accept(message)
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
        
        conversationChanged.accept(())
        messages.accept([])
        conversationIDRelay.accept(id)
        
        fetchMessagesUseCase.execute(conversationID: id)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] list in
                guard let self else { return }
                let chatMessages = list.map { item in
                    ChatMessage(type: item.role == .user ? .user : .assistant, text: item.text)
                }
                self.messages.accept(chatMessages)
                let msgs = list.map { Message(role: $0.role, content: $0.text) }
                self.contextRepository.replace(messages: msgs, summary: nil)
            })
            .disposed(by: disposeBag)
    }
}
