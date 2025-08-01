//
//  OpenAIRepositoryImpl.swift
//  chatGPT
//
//  Created by 홍정연 on 6/17/25.
//

import Foundation
import RxSwift

final class OpenAIRepositoryImpl: OpenAIRepository {
    private let service: OpenAIServiceProtocol

    init(service: OpenAIServiceProtocol) {
        self.service = service
    }
    
    /// 채팅전송
    func sendChat(messages: [Message], model: OpenAIModel, stream: Bool, completion: @escaping (Result<String, Error>) -> Void) {
        service.request(.chat(messages: messages, model: model, stream: stream)) { (result: Result<OpenAIResponse, Error>) in
            switch result {
            case .success(let decoded):
                let reply = decoded.choices.first?.message.content ?? ""
                completion(.success(reply))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func sendChatStream(messages: [Message], model: OpenAIModel) -> Observable<String> {
        service.requestStream(.chat(messages: messages, model: model, stream: true))
    }

    func sendVision(messages: [VisionMessage], model: OpenAIModel, stream: Bool, completion: @escaping (Result<String, Error>) -> Void) {
        service.request(.vision(messages: messages, model: model, stream: stream)) { (result: Result<OpenAIResponse, Error>) in
            switch result {
            case .success(let decoded):
                let reply = decoded.choices.first?.message.content ?? ""
                completion(.success(reply))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func sendVisionStream(messages: [VisionMessage], model: OpenAIModel) -> Observable<String> {
        service.requestStream(.vision(messages: messages, model: model, stream: true))
    }

    func generateImage(prompt: String, size: String, model: String, completion: @escaping (Result<[String], Error>) -> Void) {
        service.request(.image(prompt: prompt, size: size, model: model)) { (result: Result<OpenAIImageResponse, Error>) in
            switch result {
            case .success(let response):
                let urls = response.data.map { $0.url }
                completion(.success(urls))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func detectImageIntent(prompt: String) -> Single<Bool> {
        Single.create { single in
            let system = Message(role: .system,
                                 content: "Respond with 'true' only if the user explicitly creates an image or requests image editing based on an attached image. Respond with 'false' if the user is simply asking about a feature or responds that they don't need an image.")
            let user = Message(role: .user, content: prompt)
            self.service.request(.chat(messages: [system, user], model: OpenAIModel(id: "gpt-3.5-turbo"))) { (result: Result<OpenAIResponse, Error>) in
                switch result {
                case .success(let decoded):
                    let reply = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
                    single(.success(reply.contains("true")))
                case .failure(let error):
                    single(.failure(error))
                }
            }
            return Disposables.create()
        }
    }

    func analyzeUserInput(prompt: String) -> Single<PreferenceAnalysisResult> {
        Single.create { single in
            let system = Message(
                role: .system,
                content: "Analyze the user's message. Translate any non-English input into English before analysis. Record any personal facts as key-value pairs(For example, all personalized information such as occupation, hobbies, gender, age, likes and dislikes, etc.). Ignore any guesses or questions. Return only JSON { \"info\": { ... } } in English only."
            )
            let user = Message(role: .user, content: prompt)
            self.service.request(.chat(messages: [system, user], model: OpenAIModel(id: "gpt-3.5-turbo"))) { (result: Result<OpenAIResponse, Error>) in
                switch result {
                case .success(let decoded):
                    print(decoded)
                    let text = decoded.choices.first?.message.content ?? "{}"
                    if let data = text.data(using: .utf8) {
                        do {
                            let res = try JSONDecoder().decode(PreferenceAnalysisResult.self, from: data)
                            single(.success(res))
                        } catch {
                            single(.failure(OpenAIError.decodingError))
                        }
                    } else {
                        single(.failure(OpenAIError.decodingError))
                    }
                case .failure(let error):
                    single(.failure(error))
                }
            }
            return Disposables.create()
        }
    }
    
    /// 사용가능한 모델 조회
    func fetchAvailableModels(completion: @escaping (Result<[OpenAIModel], Error>) -> Void) {
        service.request(.models) { (result: Result<OpenAIModelListResponse, Error>) in
            switch result {
            case .success(let response):
                let models = response.data
                    .map { OpenAIModel(id: $0.id) }
                    .filter { $0.id.hasPrefix("gpt-") && !$0.id.contains("instruct") }
                
                completion(.success(models))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
