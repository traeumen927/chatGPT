//
//  OpenAIRepository.swift
//  chatGPT
//
//  Created by 홍정연 on 6/17/25.
//

import Foundation
import RxSwift

protocol OpenAIRepository {
    func fetchAvailableModels(completion: @escaping (Result<[OpenAIModel], Error>) -> Void)
    func sendChat(messages: [Message], model: OpenAIModel, stream: Bool, completion: @escaping (Result<String, Error>) -> Void)
    func sendChatStream(messages: [Message], model: OpenAIModel) -> Observable<String>
    func sendVision(messages: [VisionMessage], model: OpenAIModel, stream: Bool, completion: @escaping (Result<String, Error>) -> Void)
    func sendVisionStream(messages: [VisionMessage], model: OpenAIModel) -> Observable<String>

    func generateImage(prompt: String, size: String, completion: @escaping (Result<[String], Error>) -> Void)

    func detectImageIntent(prompt: String) -> Single<Bool>
}
