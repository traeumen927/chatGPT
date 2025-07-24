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

    case image(prompt: String, size: String, model: String)
    case imageVariation(image: Data, size: String, model: String)
    case imageEdit(image: Data, mask: Data?, prompt: String, size: String, model: String)
    
    /// 사용가능모델
    case models
    
    var path: String {
        switch self {
        case .chat:
            return "/chat/completions"
        case .vision:
            return "/chat/completions"
        case .image:
            return "/images/generations"
        case .imageVariation:
            return "/images/variations"
        case .imageEdit:
            return "/images/edits"

        case .models:
            return "/models"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .chat, .vision, .image, .imageVariation, .imageEdit:
            return .post
        case .models:
            return .get
        }
    }
    
    var headers: HTTPHeaders {
        switch self {
        case .imageVariation, .imageEdit:
            return [:]
        default:
            return ["Content-Type": "application/json"]
        }
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
        case .image(let prompt, let size, let model):
            return OpenAIImageRequest(prompt: prompt, n: 1, size: size, model: model)
        case .imageVariation, .imageEdit:
            return nil
        case .models:
            return nil
        }
    }

    var multipart: ((MultipartFormData) -> Void)? {
        switch self {
        case .imageVariation(let image, let size, let model):
            return { form in
                form.append(image, withName: "image", fileName: "image.png", mimeType: "image/png")
                form.append(Data("1".utf8), withName: "n")
                form.append(Data(size.utf8), withName: "size")
                form.append(Data(model.utf8), withName: "model")
            }
        case .imageEdit(let image, let mask, let prompt, let size, let model):
            return { form in
                form.append(image, withName: "image", fileName: "image.png", mimeType: "image/png")
                if let mask {
                    form.append(mask, withName: "mask", fileName: "mask.png", mimeType: "image/png")
                }
                form.append(Data(prompt.utf8), withName: "prompt")
                form.append(Data("1".utf8), withName: "n")
                form.append(Data(size.utf8), withName: "size")
                form.append(Data(model.utf8), withName: "model")
            }
        default:
            return nil
        }
    }
}
