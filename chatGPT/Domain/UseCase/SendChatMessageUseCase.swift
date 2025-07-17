//
//  SendChatMessageUseCase.swift
//  chatGPT
//
//  Created by 홍정연 on 6/17/25.
//

import Foundation
import UIKit

final class SendChatMessageUseCase {
    private let repository: OpenAIRepository

    init(repository: OpenAIRepository) {
        self.repository = repository
    }

    func execute(messages: [Message], images: [UIImage], model: OpenAIModel, stream: Bool, completion: @escaping (Result<String, Error>) -> Void) {
        repository.sendChat(messages: messages, images: images, model: model, stream: stream, completion: completion)
    }
}
