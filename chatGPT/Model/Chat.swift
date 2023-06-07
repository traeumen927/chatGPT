//
//  Chat.swift
//  chatGPT
//
//  Created by 홍정연 on 2023/06/02.
//

import Foundation

struct Chat: Decodable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let usage: Usage
    let choices: [Choice]
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case object = "object"
        case created = "created"
        case model = "model"
        case usage = "usage"
        case choices = "choices"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        object = try values.decode(String.self, forKey: .object)
        created = try values.decode(Int.self, forKey: .created)
        model = try values.decode(String.self, forKey: .model)
        usage = try values.decode(Usage.self, forKey: .usage)
        choices = try values.decode([Choice].self, forKey: .choices)
    }
}

struct Usage: Decodable {
    let prompt_tokens: Int
    let completion_tokens: Int
    let total_tokens: Int
    
    enum CodingKeys: String, CodingKey {
        case prompt_tokens = "prompt_tokens"
        case completion_tokens = "completion_tokens"
        case total_tokens = "total_tokens"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        prompt_tokens = try values.decode(Int.self, forKey: .prompt_tokens)
        completion_tokens = try values.decode(Int.self, forKey: .completion_tokens)
        total_tokens = try values.decode(Int.self, forKey: .total_tokens)
    }
}

struct Choice: Decodable {
    let message: Message
    let finish_reason: String
    let index: Int
    
    enum CodingKeys: String, CodingKey {
        case message = "message"
        case finish_reason = "finish_reason"
        case index = "index"
    }
    
    init(from decoder: Decoder) throws {
        let values = try! decoder.container(keyedBy: CodingKeys.self)
        message = try values.decode(Message.self, forKey: .message)
        finish_reason = try values.decode(String.self, forKey: .finish_reason)
        index = try values.decode(Int.self, forKey: .index)
    }
}

struct Message: Codable {
    let role: roleType
    let content: String
    
    enum CodingKeys: String, CodingKey {
        case role = "role"
        case content = "content"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        role = try values.decode(roleType.self, forKey: .role)
        content = try values.decode(String.self, forKey: .content)
    }
    
    init(role: roleType, content: String) {
        self.role = role
        self.content = content
    }
}

enum roleType: String, Codable {
    case user
    case assistant
}
