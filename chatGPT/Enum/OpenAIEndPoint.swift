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
        prompt: String,
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
            
        case .models:
            return "/models"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .chat:
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
    
    var encodableBody: OpenAIChatRequest? {
        switch self {
        case .chat(let prompt, let model, let stream, let temp):
            return OpenAIChatRequest(
                model: model.id,
                messages: [Message(role: .user, content: prompt)],
                temperature: temp,
                stream: stream
            )
        case .models:
            return nil
        }
    }
}
