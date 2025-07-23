//
//  OpenAIRepositoryImpl.swift
//  chatGPT
//
//  Created by 홍정연 on 6/17/25.
//

import Foundation
import RxSwift

final class OpenAIRepositoryImpl: OpenAIRepository {
    private let service: OpenAIService
    
    init(service: OpenAIService) {
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

    func generateImage(prompt: String, size: String, completion: @escaping (Result<[String], Error>) -> Void) {
        service.request(.image(prompt: prompt, size: size)) { (result: Result<OpenAIImageResponse, Error>) in
            switch result {
            case .success(let response):
                let urls = response.data.map { $0.url }
                completion(.success(urls))
            case .failure(let error):
                completion(.failure(error))
            }
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
