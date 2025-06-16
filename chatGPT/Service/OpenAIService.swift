//
//  OpenAIService.swift
//  chatGPT
//
//  Created by 홍정연 on 6/16/25.
//

import Foundation
import Alamofire

final class OpenAIService {
    private let session: Session
    private let apiKeyRepository: APIKeyRepository
    private let baseURL = "https://api.openai.com/v1"

    init(apiKeyRepository: APIKeyRepository, session: Session = .default) {
        self.apiKeyRepository = apiKeyRepository
        self.session = session
    }

    func request(_ endpoint: OpenAIEndpoint, completion: @escaping (Result<String, Error>) -> Void) {
        guard let apiKey = apiKeyRepository.fetchKey() else {
            completion(.failure(OpenAIError.missingAPIKey))
            return
        }

        guard let url = URL(string: baseURL + endpoint.path) else {
            completion(.failure(OpenAIError.invalidURL))
            return
        }

        guard let body = endpoint.encodableBody else {
            completion(.failure(OpenAIError.invalidRequestBody))
            return
        }

        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]

        session.request(
            url,
            method: .post,
            parameters: body,
            encoder: .json,
            headers: headers
        )
        .validate()
        .responseDecodable(of: OpenAIResponse.self) { response in
            switch response.result {
            case .success(let decoded):
                let reply = decoded.choices.first?.message.content ?? ""
                completion(.success(reply))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
