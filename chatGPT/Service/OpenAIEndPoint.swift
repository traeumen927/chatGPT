//
//  OpenAIEndPoint.swift
//  chatGPT
//
//  Created by 홍정연 on 6/16/25.
//

import Foundation
import Alamofire

enum OpenAIEndpoint {
    
    /// 질문요청
    case chat(
        messages: [Message],
        model: OpenAIModel,
        stream: Bool = false,
        temperature: Double = 0.7
    )

    case vision(
        messages: [VisionMessage],
        model: OpenAIModel,
        stream: Bool = false,
        temperature: Double = 0.7
    )
    
    /// 사용가능모델
    case models
    
    var path: String {
        switch self {
        case .chat:
            return "/chat/completions"
        case .vision:
            return "/chat/completions"

        case .models:
            return "/models"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .chat, .vision:
            return .post
        case .models:
            return .get
        }
    }
    
    var headers: HTTPHeaders {
        return [
            "Content-Type": "application/json"
        ]
    }
    
    var encodableBody: Encodable? {
        switch self {
        case .chat(let messages, let model, let stream, let temp):
            return OpenAIChatRequest(
                model: model.id,
                messages: messages,
                temperature: temp,
                stream: stream
            )
        case .vision(let messages, let model, let stream, let temp):
            return OpenAIVisionChatRequest(
                model: model.id,
                messages: messages,
                temperature: temp,
                stream: stream
            )
        case .models:
            return nil
        }
    }
}
