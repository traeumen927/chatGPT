//
//  ChatContextRepository.swift
//  chatGPT
//
//  Created by Codex on 2024.
//

import Foundation

protocol ChatContextRepository {
    var messages: [Message] { get }
    var summary: String? { get }
    func append(role: RoleType, content: String)
    func updateSummary(_ summary: String)
    func trim(to maxCount: Int)
    func clear()
}
