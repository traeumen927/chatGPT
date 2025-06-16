//
//  OpenAIResponse.swift
//  chatGPT
//
//  Created by 홍정연 on 6/16/25.
//

import Foundation

struct OpenAIResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
