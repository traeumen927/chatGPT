//
//  FetchAvailableModelsUseCase.swift
//  chatGPT
//
//  Created by 홍정연 on 6/17/25.
//

import Foundation

final class FetchAvailableModelsUseCase {
    private let repository: OpenAIRepository

    init(repository: OpenAIRepository) {
        self.repository = repository
    }

    func execute(completion: @escaping (Result<[OpenAIModel], Error>) -> Void) {
        repository.fetchAvailableModels(completion: completion)
    }
}
