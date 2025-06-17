//
//  OpenAIModelListResponse.swift
//  chatGPT
//
//  Created by 홍정연 on 6/17/25.
//

import Foundation

struct OpenAIModelListResponse: Decodable {
    let data: [OpenAIModelInfo]
}

struct OpenAIModelInfo: Decodable {
    let id: String
    let ownedBy: String

    enum CodingKeys: String, CodingKey {
        case id
        case ownedBy = "owned_by"
    }
}
