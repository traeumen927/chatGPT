//
//  ChatViewModel.swift
//  chatGPT
//
//  Created by 홍정연 on 6/17/25.
//

import Foundation
import UIKit
import RxSwift
import RxRelay

final class ChatViewModel {
    enum MessageType {
        case user
        case assistant
        case error
    }
    
    struct ChatMessage: Hashable, Identifiable {
        let id: UUID
        let type: MessageType
        let text: String
        
        init(id: UUID = UUID(), type: MessageType, text: String) {
            self.id = id
            self.type = type
            self.text = text
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
    private let fetchPreferenceUseCase: FetchUserPreferenceUseCase
    private let updatePreferenceUseCase: UpdateUserPreferenceUseCase
    private let uploadFilesUseCase: UploadFilesUseCase
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
         contextRepository: ChatContextRepository,
         fetchPreferenceUseCase: FetchUserPreferenceUseCase,
         updatePreferenceUseCase: UpdateUserPreferenceUseCase,
         uploadFilesUseCase: UploadFilesUseCase) {
        self.sendMessageUseCase = sendMessageUseCase
        self.summarizeUseCase = summarizeUseCase
        self.saveConversationUseCase = saveConversationUseCase
        self.appendMessageUseCase = appendMessageUseCase
        self.fetchMessagesUseCase = fetchMessagesUseCase
        self.contextRepository = contextRepository
        self.fetchPreferenceUseCase = fetchPreferenceUseCase
        self.updatePreferenceUseCase = updatePreferenceUseCase
        self.uploadFilesUseCase = uploadFilesUseCase
    }
    
    func send(prompt: String, images: [UIImage] = [], files: [URL] = [], model: OpenAIModel, stream: Bool) {
        let isFirst = messages.value.isEmpty
        appendMessage(ChatMessage(type: .user, text: prompt))
        
        
        updatePreferenceUseCase.execute(prompt: prompt)
            .subscribe()
            .disposed(by: disposeBag)
        
        let imageData = images.compactMap { $0.jpegData(compressionQuality: 0.8) }
        let fileData = files.compactMap { try? Data(contentsOf: $0) }
        let allData = imageData + fileData
        
        uploadFilesUseCase.execute(datas: allData)
            .catchAndReturn([])
            .flatMap { [weak self] urls -> Single<UserPreference?> in
                guard let self else { return .just(nil) }
                if let id = self.conversationID {
                    self.appendMessageUseCase.execute(conversationID: id,
                                                      role: .user,
                                                      text: prompt,
                                                      urls: urls.map { $0.absoluteString })
                    .subscribe()
                    .disposed(by: self.disposeBag)
                }
                return self.fetchPreferenceUseCase.execute().catchAndReturn(nil).map { pref in
                    self.sendInternal(prompt: prompt,
                                      images: images,
                                      files: files,
                                      urls: urls.map { $0.absoluteString },
                                      model: model,
                                      stream: stream,
                                      preference: pref,
                                      isFirst: isFirst)
                    return pref
                }
            }
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    private func sendInternal(prompt: String,
                              images: [UIImage],
                              files: [URL],
                              urls: [String],
                              model: OpenAIModel,
                              stream: Bool,
                              preference: UserPreference?,
                              isFirst: Bool) {
        guard stream else {
            let prefMessage = self.preferenceText(from: preference)
            let imageData = images.compactMap { $0.jpegData(compressionQuality: 0.8) }
            let fileData = files.compactMap { try? Data(contentsOf: $0) }
            sendMessageUseCase.execute(prompt: prompt,
                                       model: model,
                                       stream: false,
                                       preference: prefMessage,
                                       images: imageData,
                                       files: fileData) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let reply):
                    self.appendMessage(ChatMessage(type: .assistant, text: reply))
                    if let id = self.conversationID, !isFirst {
                        self.appendMessageUseCase.execute(conversationID: id,
                                                          role: .assistant,
                                                          text: reply,
                                                          urls: [])
                        .subscribe()
                        .disposed(by: self.disposeBag)
                    }
                    if isFirst {
                        self.saveFirstConversation(question: prompt,
                                                   questionURLs: urls,
                                                   answer: reply,
                                                   answerURLs: [],
                                                   model: model)
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
        
        let prefMessage = self.preferenceText(from: preference)
        let imageData = images.compactMap { $0.jpegData(compressionQuality: 0.8) }
        let fileData = files.compactMap { try? Data(contentsOf: $0) }
        sendMessageUseCase.stream(prompt: prompt, model: model, preference: prefMessage, images: imageData, files: fileData)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] chunk in
                guard let self else { return }
                fullText += chunk
                self.updateMessage(id: assistantID, text: fullText, updateList: false)
            }, onError: { [weak self] error in
                let message = (error as? OpenAIError)?.errorMessage ?? error.localizedDescription
                self?.updateMessage(id: assistantID, text: message, type: .error)
            }, onCompleted: { [weak self] in
                guard let self else { return }
                self.updateMessage(id: assistantID, text: fullText)
                self.sendMessageUseCase.finalize(prompt: prompt, reply: fullText, model: model)
                if let id = self.conversationID, !isFirst {
                    self.appendMessageUseCase.execute(conversationID: id,
                                                      role: .assistant,
                                                      text: fullText,
                                                      urls: [])
                    .subscribe()
                    .disposed(by: self.disposeBag)
                }
                if isFirst {
                    self.saveFirstConversation(question: prompt,
                                               questionURLs: urls,
                                               answer: fullText,
                                               answerURLs: [],
                                               model: model)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func preferenceText(from preference: UserPreference?) -> String? {
        guard let preference else { return nil }
        let sorted = preference.items.sorted { $0.updatedAt > $1.updatedAt }
        let texts = sorted.map { "\($0.relation.rawValue): \($0.key)" }
        let result = texts.joined(separator: ", ")
        return result.isEmpty ? nil : result
    }
    
    private func saveFirstConversation(question: String,
                                       questionURLs: [String],
                                       answer: String,
                                       answerURLs: [String],
                                       model: OpenAIModel) {
        let history = [
            Message(role: .user, content: question),
            Message(role: .assistant, content: answer)
        ]
        
        summarizeUseCase.execute(messages: history, model: model) { [weak self] result in
            guard let self = self else { return }
            if case .success(let title) = result {
                let cleanTitle = title.removingQuotes()
                self.saveConversationUseCase.execute(title: cleanTitle,
                                                     question: question,
                                                     questionURLs: questionURLs,
                                                     answer: answer,
                                                     answerURLs: answerURLs)
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
    
    private func updateMessage(id: UUID,
                               text: String,
                               type: MessageType? = nil,
                               updateList: Bool = true) {
        var current = messages.value
        guard let index = current.firstIndex(where: { $0.id == id }) else { return }
        let old = current[index]
        let newMsg = ChatMessage(id: old.id, type: type ?? old.type, text: text)
        current[index] = newMsg
        if updateList { messages.accept(current) }
        streamingMessageRelay.accept(newMsg)
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
                    let attachments = (item.urls ?? [])
                        .map { url -> String in
                            "![image](\(url))"
                        }
                        .joined(separator: "\n")
                    let text = attachments.isEmpty ? item.text : item.text + "\n" + attachments
                    return ChatMessage(type: item.role == .user ? .user : .assistant, text: text)
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
