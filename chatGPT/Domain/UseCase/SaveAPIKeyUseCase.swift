//
//  SaveAPIKeyUseCase.swift
//  chatGPT
//
//  Created by 홍정연 on 6/11/25.
//

import Foundation

final class SaveAPIKeyUseCase {
    private let repository: APIKeyRepository

    init(repository: APIKeyRepository) {
        self.repository = repository
    }

    func execute(key: String) throws {
        try repository.save(key: key)
    }
}
