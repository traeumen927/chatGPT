//
//  ApiKeyRepository.swift
//  chatGPT
//
//  Created by 홍정연 on 6/11/25.
//

import Foundation

protocol APIKeyRepository {
    func fetchKey() -> String?
    func save(key: String) throws
}
