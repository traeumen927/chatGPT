//
//  OpenAICompletionBody.swift
//  chatGPT
//
//  Created by 홍정연 on 2023/06/02.
//

import Foundation

struct OpenAICompletionBody: Encodable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let stream: Bool
}
