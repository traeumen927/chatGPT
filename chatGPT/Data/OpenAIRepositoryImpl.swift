//
//  OpenAIRepositoryImpl.swift
//  chatGPT
//
//  Created by 홍정연 on 6/17/25.
//

import Foundation
import UIKit
import RxSwift

final class OpenAIRepositoryImpl: OpenAIRepository {
    private let service: OpenAIService
    
    init(service: OpenAIService) {
        self.service = service
    }
    
    /// 채팅전송
    func sendChat(messages: [Message], images: [UIImage], model: OpenAIModel, stream: Bool, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint: OpenAIEndpoint
        if images.isEmpty {
            endpoint = .chat(messages: messages, model: model, stream: stream)
        } else {
            let datas = images.compactMap { $0.pngData() }
            endpoint = .vision(messages: messages, imageDatas: datas, model: model, stream: stream)
        }
        service.request(endpoint) { (result: Result<OpenAIResponse, Error>) in
            switch result {
            case .success(let decoded):
                let reply = decoded.choices.first?.message.content ?? ""
                completion(.success(reply))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func sendChatStream(messages: [Message], images: [UIImage], model: OpenAIModel) -> Observable<String> {
        if images.isEmpty {
            return service.requestStream(.chat(messages: messages, model: model, stream: true))
        } else {
            let datas = images.compactMap { $0.pngData() }
            return service.requestStream(.vision(messages: messages, imageDatas: datas, model: model, stream: true))
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
