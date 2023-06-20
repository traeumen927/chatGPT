//
//  StreamChat.swift
//  chatGPT
//
//  Created by 홍정연 on 2023/06/02.
//

import Foundation


struct StreamChat: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [StreamChoice]
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case object = "object"
        case created = "created"
        case model = "model"
        case choices = "choices"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        object = try values.decode(String.self, forKey: .object)
        created = try values.decode(Int.self, forKey: .created)
        model = try values.decode(String.self, forKey: .model)
        choices = try values.decode([StreamChoice].self, forKey: .choices)
    }
}

struct StreamChoice: Codable {
    let delta: Delta
    let finish_reason: String?
    let index: Int
    
    enum CodingKeys: String, CodingKey {
        case delta = "delta"
        case finish_reason = "finish_reason"
        case index = "index"
    }
    
    init(from decoder: Decoder) throws {
        let values = try! decoder.container(keyedBy: CodingKeys.self)
        delta = try values.decode(Delta.self, forKey: .delta)
        finish_reason = try values.decodeIfPresent(String.self, forKey: .finish_reason)
        index = try values.decode(Int.self, forKey: .index)
    }
}

struct Delta: Codable {
    let role: roleType?
    let content: String?
}

