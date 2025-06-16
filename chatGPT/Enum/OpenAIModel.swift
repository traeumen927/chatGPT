//
//  OpenAIModel.swift
//  chatGPT
//
//  Created by 홍정연 on 6/16/25.
//

import Foundation

enum OpenAIModel: String {
    case gpt35 = "gpt-3.5-turbo"
    case gpt4 = "gpt-4"
    case gpt4o = "gpt-4o"

    var isStreamingSupported: Bool {
        return true
    }
}
