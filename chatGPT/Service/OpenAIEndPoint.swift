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

    /// Vision 모델 질문요청
    case vision(
        messages: [Message],
        imageDatas: [Data],
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
        case .chat:
            return .post
        case .vision:
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
        case .vision(let messages, let imageDatas, let model, let stream, let temp):
            let images = imageDatas.map { "data:image/png;base64,\($0.base64EncodedString())" }
            let visMessages: [OpenAIVisionChatRequest.VisionMessage] = messages.map {
                let content = [OpenAIVisionChatRequest.VisionMessage.VisionContent(type: "text", text: $0.content, image_url: nil)]
                return OpenAIVisionChatRequest.VisionMessage(role: $0.role, content: content)
            }
            let userContents = [
                OpenAIVisionChatRequest.VisionMessage.VisionContent(type: "text", text: messages.last?.content ?? "", image_url: nil)
            ] + images.map {
                OpenAIVisionChatRequest.VisionMessage.VisionContent(type: "image_url", text: nil, image_url: .init(url: $0))
            }
            var final = visMessages
            if !final.isEmpty { final.removeLast() }
            final.append(OpenAIVisionChatRequest.VisionMessage(role: .user, content: userContents))
            return OpenAIVisionChatRequest(
                model: model.id,
                messages: final,
                temperature: temp,
                stream: stream
            )
        case .models:
            return nil
        }
    }
}
