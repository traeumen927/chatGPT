//
//  OpenAIChatRequest.swift
//  chatGPT
//
//  Created by 홍정연 on 6/16/25.
//

import Foundation

struct OpenAIChatRequest: Encodable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let stream: Bool
}

struct Message: Codable {
    let role: RoleType
    let content: String
}
