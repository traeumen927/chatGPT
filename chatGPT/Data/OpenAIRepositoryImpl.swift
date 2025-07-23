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
    func sendChat(messages: [Message], model: OpenAIModel, stream: Bool, completion: @escaping (Result<OpenAIChatResult, Error>) -> Void) {
        service.request(.chat(messages: messages, model: model, stream: stream)) { (result: Result<OpenAIResponse, Error>) in
            switch result {
            case .success(let decoded):
                let msg = decoded.choices.first?.message
                let reply = msg?.content ?? ""
                let urls = msg?.urls ?? []
                completion(.success(OpenAIChatResult(text: reply, urls: urls)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func sendChatStream(messages: [Message], model: OpenAIModel) -> Observable<String> {
        service.requestStream(.chat(messages: messages, model: model, stream: true))
    }

    func sendVision(messages: [VisionMessage], model: OpenAIModel, stream: Bool, completion: @escaping (Result<OpenAIChatResult, Error>) -> Void) {
        service.request(.vision(messages: messages, model: model, stream: stream)) { (result: Result<OpenAIResponse, Error>) in
            switch result {
            case .success(let decoded):
                let msg = decoded.choices.first?.message
                let reply = msg?.content ?? ""
                let urls = msg?.urls ?? []
                completion(.success(OpenAIChatResult(text: reply, urls: urls)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func sendVisionStream(messages: [VisionMessage], model: OpenAIModel) -> Observable<String> {
        service.requestStream(.vision(messages: messages, model: model, stream: true))
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

