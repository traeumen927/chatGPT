//
//  OpenAIVisionChatRequest.swift
//  chatGPT
//
//  Created by Codex on 2024.
//

import Foundation

struct OpenAIVisionChatRequest: Encodable {
    struct VisionMessage: Encodable {
        struct VisionContent: Encodable {
            let type: String
            let text: String?
            let image_url: ImageURL?
        }
        struct ImageURL: Encodable {
            let url: String
        }
        let role: RoleType
        let content: [VisionContent]
    }
    let model: String
    let messages: [VisionMessage]
    let temperature: Double
    let stream: Bool
}
