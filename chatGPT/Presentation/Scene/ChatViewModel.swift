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
        let urls: [String]

        init(id: UUID = UUID(), type: MessageType, text: String, urls: [String] = []) {
            self.id = id
            self.type = type
            self.text = text
            self.urls = urls
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
    private let updatePreferenceUseCase: AnalyzeUserInputUseCase
    private let fetchInfoUseCase: FetchUserInfoUseCase
    private let uploadFilesUseCase: UploadFilesUseCase
    private let generateImageUseCase: GenerateImageUseCase
    private let detectImageRequestUseCase: DetectImageRequestUseCase
    private let disposeBag = DisposeBag()

    private var userInfo = UserInfo(attributes: [:])
    
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
         updatePreferenceUseCase: AnalyzeUserInputUseCase,
         fetchInfoUseCase: FetchUserInfoUseCase,
         uploadFilesUseCase: UploadFilesUseCase,
         generateImageUseCase: GenerateImageUseCase,
         detectImageRequestUseCase: DetectImageRequestUseCase) {
        self.sendMessageUseCase = sendMessageUseCase
        self.summarizeUseCase = summarizeUseCase
        self.saveConversationUseCase = saveConversationUseCase
        self.appendMessageUseCase = appendMessageUseCase
        self.fetchMessagesUseCase = fetchMessagesUseCase
        self.contextRepository = contextRepository
        self.updatePreferenceUseCase = updatePreferenceUseCase
        self.fetchInfoUseCase = fetchInfoUseCase
        self.uploadFilesUseCase = uploadFilesUseCase
        self.generateImageUseCase = generateImageUseCase
        self.detectImageRequestUseCase = detectImageRequestUseCase
        fetchInfoUseCase.execute()
            .subscribe(onSuccess: { [weak self] info in
                self?.userInfo = info ?? UserInfo(attributes: [:])
            })
            .disposed(by: disposeBag)
    }
    
    func send(prompt: String, attachments: [Attachment] = [], model: OpenAIModel, stream: Bool) {
        detectImageRequestUseCase.execute(prompt: prompt)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] isImage in
                guard let self else { return }
                if isImage {
                    self.generateImage(prompt: prompt, size: "1024x1024", model: model, attachments: attachments)
                } else {
                    self.processSend(prompt: prompt, attachments: attachments, model: model, stream: stream)
                }
            }, onFailure: { [weak self] _ in
                self?.processSend(prompt: prompt, attachments: attachments, model: model, stream: stream)
            })
            .disposed(by: disposeBag)
    }

    private func processSend(prompt: String, attachments: [Attachment], model: OpenAIModel, stream: Bool) {
        let isFirst = messages.value.isEmpty
        let messageID = UUID()
        appendMessage(ChatMessage(id: messageID, type: .user, text: prompt))


        updatePreferenceUseCase.execute(prompt: prompt)
            .subscribe()
            .disposed(by: disposeBag)
        
        let allData = attachments.compactMap { item -> Data? in
            switch item {
            case .image(let img):
                return img.jpegData(compressionQuality: 0.8)
            case .file(let url):
                return try? Data(contentsOf: url)
            }
        }
        
        uploadFilesUseCase.execute(datas: allData)
            .catchAndReturn([])
            .subscribe(onSuccess: { [weak self] urls in
                guard let self else { return }
                self.updateMessage(id: messageID, text: prompt, urls: urls.map { $0.absoluteString })
                if let id = self.conversationID {
                    self.appendMessageUseCase.execute(conversationID: id,
                                                      role: .user,
                                                      text: prompt,
                                                      urls: urls.map { $0.absoluteString })
                    .subscribe()
                    .disposed(by: self.disposeBag)
                }
                self.sendInternal(prompt: prompt,
                                  attachments: attachments,
                                  urls: urls.map { $0.absoluteString },
                                  model: model,
                                  stream: stream,
                                  isFirst: isFirst)
            })
            .disposed(by: disposeBag)
    }
    
    private func sendInternal(prompt: String,
                              attachments: [Attachment],
                              urls: [String],
                              model: OpenAIModel,
                              stream: Bool,
                              isFirst: Bool) {
        guard stream else {
            let imageData = attachments.compactMap { item -> Data? in
                if case let .image(img) = item { return img.jpegData(compressionQuality: 0.8) }
                return nil
            }
            let fileData = attachments.compactMap { item -> Data? in
                if case let .file(url) = item { return try? Data(contentsOf: url) }
                return nil
            }
            let profileMsg = self.infoText(from: self.userInfo)
            sendMessageUseCase.execute(prompt: prompt,
                                       model: model,
                                       stream: false,
                                       preference: nil,
                                       profile: profileMsg,
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
        let imageData = attachments.compactMap { item -> Data? in
            if case let .image(img) = item { return img.jpegData(compressionQuality: 0.8) }
            return nil
        }
        let fileData = attachments.compactMap { item -> Data? in
            if case let .file(url) = item { return try? Data(contentsOf: url) }
            return nil
        }
        let profileMsg = self.infoText(from: self.userInfo)
        sendMessageUseCase.stream(prompt: prompt,
                                  model: model,
                                  preference: nil,
                                  profile: profileMsg,
                                  images: imageData,
                                  files: fileData)
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

    func infoText(from info: UserInfo) -> String? {
        let parts = info.attributes
            .sorted { $0.key < $1.key }
            .map { key, facts in
                let values = facts.map { $0.value }.joined(separator: ", ")
                return "\(key): \(values)"
            }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
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
                               urls: [String]? = nil,
                               updateList: Bool = true) {
        var current = messages.value
        guard let index = current.firstIndex(where: { $0.id == id }) else { return }
        let old = current[index]
        let newMsg = ChatMessage(id: old.id,
                                 type: type ?? old.type,
                                 text: text,
                                 urls: urls ?? old.urls)
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
                    ChatMessage(type: item.role == .user ? .user : .assistant,
                                text: item.text,
                                urls: item.urls ?? [])
                }
                self.conversationChanged.accept(())
                self.messages.accept(chatMessages)
                self.conversationIDRelay.accept(id)
                let msgs = list.map { Message(role: $0.role, content: $0.text) }
                self.contextRepository.replace(messages: msgs, summary: nil)
            })
            .disposed(by: disposeBag)
    }

    func generateImage(prompt: String, size: String, model: OpenAIModel, attachments: [Attachment] = []) {
        let isFirst = messages.value.isEmpty
        let id = UUID()
        appendMessage(ChatMessage(id: id, type: .user, text: prompt))

        let uploadData = attachments.compactMap { item -> Data? in
            switch item {
            case .image(let img):
                return img.jpegData(compressionQuality: 0.8)
            case .file(let url):
                return try? Data(contentsOf: url)
            }
        }

        uploadFilesUseCase.execute(datas: uploadData)
            .catchAndReturn([])
            .subscribe(onSuccess: { [weak self] urls in
                self?.generateImageInternal(prompt: prompt,
                                            size: size,
                                            model: model,
                                            uploaded: urls.map { $0.absoluteString },
                                            messageID: id,
                                            isFirst: isFirst)
            })
            .disposed(by: disposeBag)
    }

    private func generateImageInternal(prompt: String,
                                       size: String,
                                       model: OpenAIModel,
                                       uploaded: [String],
                                       messageID: UUID,
                                       isFirst: Bool) {
        updateMessage(id: messageID, text: prompt, urls: uploaded)

        if let convID = conversationID {
            appendMessageUseCase.execute(conversationID: convID,
                                         role: .user,
                                         text: prompt,
                                         urls: uploaded)
                .subscribe()
                .disposed(by: disposeBag)
        }

        generateImageUseCase.execute(prompt: prompt, size: size) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let urls):
                let markdown = urls.map { "![\(prompt)](\($0))" }.joined(separator: "\n")
                self.appendMessage(ChatMessage(type: .assistant, text: markdown))
                if let convID = self.conversationID {
                    self.appendMessageUseCase.execute(conversationID: convID,
                                                      role: .assistant,
                                                      text: markdown)
                        .subscribe()
                        .disposed(by: self.disposeBag)
                } else if isFirst {
                    let history = [
                        Message(role: .user, content: prompt),
                        Message(role: .assistant, content: "image")
                    ]
                    self.summarizeUseCase.execute(messages: history, model: model) { [weak self] summaryResult in
                        guard let self else { return }
                        if case .success(let title) = summaryResult {
                            let clean = title.removingQuotes()
                            self.saveConversationUseCase.execute(title: clean,
                                                                  question: prompt,
                                                                  questionURLs: uploaded,
                                                                  answer: markdown,
                                                                  answerURLs: [])
                                .subscribe(onSuccess: { [weak self] id in
                                    self?.conversationIDRelay.accept(id)
                                    self?.draftMessages = nil
                                })
                                .disposed(by: self.disposeBag)
                        }
                    }
                }
            case .failure(let error):
                let message = (error as? OpenAIError)?.errorMessage ?? error.localizedDescription
                self.appendMessage(ChatMessage(type: .error, text: message))
            }
        }
    }
}
