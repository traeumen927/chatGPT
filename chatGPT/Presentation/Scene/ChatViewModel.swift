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
        let attachments: [Attachment]

        init(id: UUID = UUID(), type: MessageType, text: String, attachments: [Attachment] = []) {
            self.id = id
            self.type = type
            self.text = text
            self.attachments = attachments
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
            lhs.id == rhs.id
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
    private let uploadFilesUseCase: UploadFilesUseCase
    private let contextRepository: ChatContextRepository
    private let fetchPreferenceUseCase: FetchUserPreferenceUseCase
    private let updatePreferenceUseCase: UpdateUserPreferenceUseCase
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
         uploadFilesUseCase: UploadFilesUseCase,
         contextRepository: ChatContextRepository,
         fetchPreferenceUseCase: FetchUserPreferenceUseCase,
         updatePreferenceUseCase: UpdateUserPreferenceUseCase) {
        self.sendMessageUseCase = sendMessageUseCase
        self.summarizeUseCase = summarizeUseCase
        self.saveConversationUseCase = saveConversationUseCase
        self.appendMessageUseCase = appendMessageUseCase
        self.fetchMessagesUseCase = fetchMessagesUseCase
        self.uploadFilesUseCase = uploadFilesUseCase
        self.contextRepository = contextRepository
        self.fetchPreferenceUseCase = fetchPreferenceUseCase
        self.updatePreferenceUseCase = updatePreferenceUseCase
    }
    
    func send(prompt: String, images: [UIImage] = [], files: [URL] = [], model: OpenAIModel, stream: Bool) {
        let isFirst = messages.value.isEmpty
        let localAttachments: [Attachment] = images.map { .image($0) } + files.map { .file($0) }
        appendMessage(ChatMessage(type: .user, text: prompt, attachments: localAttachments))

        if conversationID != nil {
            // will be saved after receiving reply
        }

        updatePreferenceUseCase.execute(prompt: prompt)
            .subscribe()
            .disposed(by: disposeBag)

        fetchPreferenceUseCase.execute()
            .catchAndReturn(nil)
            .subscribe(onSuccess: { [weak self] preference in
                self?.sendInternal(prompt: prompt,
                                   images: images,
                                   files: files,
                                   model: model,
                                   stream: stream,
                                   preference: preference,
                                   isFirst: isFirst)
            })
            .disposed(by: disposeBag)
    }

    private func sendInternal(prompt: String,
                              images: [UIImage],
                              files: [URL],
                              model: OpenAIModel,
                              stream: Bool,
                              preference: UserPreference?,
                              isFirst: Bool) {
        let imageData = images.compactMap { $0.jpegData(compressionQuality: 0.8) }
        let fileData = files.compactMap { try? Data(contentsOf: $0) }
        let allData = imageData + fileData
        let exts = images.map { _ in "jpg" } + files.map { $0.pathExtension }

        uploadFilesUseCase.execute(datas: allData, extensions: exts)
            .catchAndReturn([])
            .subscribe(onSuccess: { [weak self] urls in
                self?.sendToOpenAI(prompt: prompt,
                                   images: imageData,
                                   files: fileData,
                                   urls: urls,
                                   model: model,
                                   stream: stream,
                                   preference: preference,
                                   isFirst: isFirst)
            })
            .disposed(by: disposeBag)
    }

    private func sendToOpenAI(prompt: String,
                              images: [Data],
                              files: [Data],
                              urls: [String],
                              model: OpenAIModel,
                              stream: Bool,
                              preference: UserPreference?,
                              isFirst: Bool) {
        guard stream else {
            let prefMessage = self.preferenceText(from: preference)
            sendMessageUseCase.execute(prompt: prompt,
                                      model: model,
                                      stream: false,
                                      preference: prefMessage,
                                      images: images,
                                      files: files) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let reply):
                    self.appendMessage(ChatMessage(type: .assistant, text: reply))
                    if let id = self.conversationID, !isFirst {
                        self.appendMessageUseCase.execute(conversationID: id,
                                                          role: .assistant,
                                                          text: reply,
                                                          files: [])
                            .subscribe()
                            .disposed(by: self.disposeBag)
                        self.appendMessageUseCase.execute(conversationID: id,
                                                          role: .user,
                                                          text: prompt,
                                                          files: urls)
                            .subscribe()
                            .disposed(by: self.disposeBag)
                    }
                    if isFirst {
                        self.saveFirstConversation(question: prompt, files: urls, answer: reply, model: model)
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
                                                      files: [])
                        .subscribe()
                        .disposed(by: self.disposeBag)
                    self.appendMessageUseCase.execute(conversationID: id,
                                                      role: .user,
                                                      text: prompt,
                                                      files: urls)
                        .subscribe()
                        .disposed(by: self.disposeBag)
                }
                if isFirst {
                    self.saveFirstConversation(question: prompt, files: urls, answer: fullText, model: model)
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
    
    private func saveFirstConversation(question: String, files: [String], answer: String, model: OpenAIModel) {
        let history = [
            Message(role: .user, content: question),
            Message(role: .assistant, content: answer)
        ]
        
        summarizeUseCase.execute(messages: history, model: model) { [weak self] result in
            guard let self = self else { return }
            if case .success(let title) = result {
                let cleanTitle = title.removingQuotes()
                self.saveConversationUseCase.execute(title: cleanTitle, question: question, files: files, answer: answer)
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
        let newMsg = ChatMessage(id: old.id, type: type ?? old.type, text: text, attachments: old.attachments)
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
                    let attachments = item.files.compactMap { URL(string: $0) }.map { url -> Attachment in
                        url.pathExtension.lowercased() == "pdf" ? .remoteFile(url) : .remoteImage(url)
                    }
                    return ChatMessage(type: item.role == .user ? .user : .assistant,
                                       text: item.text,
                                       attachments: attachments)
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
