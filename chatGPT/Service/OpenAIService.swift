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
    
    func request<T: Decodable>(_ endpoint: OpenAIEndpoint, completion: @escaping (Result<T, Error>) -> Void) {
        guard let apiKey = apiKeyRepository.fetchKey() else {
            completion(.failure(OpenAIError.missingAPIKey))
            return
        }
        
        guard let url = URL(string: baseURL + endpoint.path) else {
            completion(.failure(OpenAIError.invalidURL))
            return
        }
        
        var headers = endpoint.headers
        headers.add(name: "Authorization", value: "Bearer \(apiKey)")
        
        let request: DataRequest
        
        if let body = endpoint.encodableBody {
            request = session.request(
                url,
                method: endpoint.method,
                parameters: body,
                encoder: .json,
                headers: headers
            )
        } else {
            request = session.request(
                url,
                method: endpoint.method,
                headers: headers
            )
        }
        
        request
            .validate()
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let decoded):
                    completion(.success(decoded))
                case .failure(let error):
                    completion(.failure(error as Error))
                }
            }
    }
}
