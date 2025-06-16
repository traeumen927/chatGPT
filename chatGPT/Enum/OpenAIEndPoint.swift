//
//  OpenAIEndPoint.swift
//  chatGPT
//
//  Created by 홍정연 on 6/16/25.
//

import Foundation

enum OpenAIEndpoint {
    case chat(
        prompt: String,
        model: OpenAIModel = .gpt35,
        stream: Bool = false,
        temperature: Double = 0.7
    )

    var path: String {
        switch self {
        case .chat:
            return "/chat/completions"
        }
    }

    var encodableBody: OpenAIChatRequest? {
        switch self {
        case .chat(let prompt, let model, let stream, let temp):
            return OpenAIChatRequest(
                model: model.rawValue,
                messages: [Message(role: .user, content: prompt)],
                temperature: temp,
                stream: stream
            )
        }
    }
}
