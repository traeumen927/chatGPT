//
//  OpenAIRepository.swift
//  chatGPT
//
//  Created by 홍정연 on 6/17/25.
//

import Foundation

protocol OpenAIRepository {
    func fetchAvailableModels(completion: @escaping (Result<[OpenAIModel], Error>) -> Void)
    func sendChat(messages: [Message], model: OpenAIModel, stream: Bool, completion: @escaping (Result<String, Error>) -> Void)
}
