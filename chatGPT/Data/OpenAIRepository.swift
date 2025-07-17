//
//  OpenAIRepository.swift
//  chatGPT
//
//  Created by 홍정연 on 6/17/25.
//

import Foundation
import UIKit
import RxSwift

protocol OpenAIRepository {
    func fetchAvailableModels(completion: @escaping (Result<[OpenAIModel], Error>) -> Void)
    func sendChat(messages: [Message], images: [UIImage], model: OpenAIModel, stream: Bool, completion: @escaping (Result<String, Error>) -> Void)
    func sendChatStream(messages: [Message], images: [UIImage], model: OpenAIModel) -> Observable<String>
}
