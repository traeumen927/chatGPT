//
//  OpenAIService.swift
//  chatGPT
//
//  Created by 홍정연 on 6/16/25.
//

import Foundation
import Alamofire
import RxSwift

final class CancelToken {
    private let onCancel: () -> Void
    init(_ onCancel: @escaping () -> Void) { self.onCancel = onCancel }
    func cancel() { onCancel() }
}

final class OpenAIService: OpenAIServiceProtocol {
    private let session: Session
    private let apiKeyRepository: APIKeyRepository
    private let baseURL = "https://api.openai.com/v1"
    
    init(apiKeyRepository: APIKeyRepository, session: Session = .default) {
        self.apiKeyRepository = apiKeyRepository
        self.session = session
    }
    
    @discardableResult
    func request<T: Decodable>(_ endpoint: OpenAIEndpoint,
                               completion: @escaping (Result<T, Error>) -> Void) -> CancelToken {
        guard let apiKey = apiKeyRepository.fetchKey() else {
            completion(.failure(OpenAIError.missingAPIKey))
            return CancelToken { }
        }

        guard let url = URL(string: baseURL + endpoint.path) else {
            completion(.failure(OpenAIError.invalidURL))
            return CancelToken { }
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
        return CancelToken { request.cancel() }
    }
    
    func requestStream(_ endpoint: OpenAIEndpoint) -> Observable<String> {
        Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            guard let apiKey = apiKeyRepository.fetchKey() else {
                observer.onError(OpenAIError.missingAPIKey)
                return Disposables.create()
            }
            
            guard let url = URL(string: baseURL + endpoint.path) else {
                observer.onError(OpenAIError.invalidURL)
                return Disposables.create()
            }
            
            var headers = endpoint.headers
            headers.add(name: "Authorization", value: "Bearer \(apiKey)")
            
            let request: DataStreamRequest
            if let body = endpoint.encodableBody {
                request = session.streamRequest(
                    url,
                    method: endpoint.method,
                    parameters: body,
                    encoder: .json,
                    headers: headers
                )
            } else {
                request = session.streamRequest(
                    url,
                    method: endpoint.method,
                    headers: headers
                )
            }
            
            request.validate().responseStream { stream in
                switch stream.event {
                case let .stream(result):
                    switch result {
                    case let .success(data):
                        if let chunk = String(data: data, encoding: .utf8) {
                            for line in chunk.split(separator: "\n") {
                                guard line.hasPrefix("data: ") else { continue }
                                let jsonString = line.dropFirst(6)
                                if jsonString == "[DONE]" {
                                    observer.onCompleted()
                                    return
                                }
                                if let jsonData = jsonString.data(using: .utf8),
                                   let response = try? JSONDecoder().decode(OpenAIStreamResponse.self, from: jsonData),
                                   let content = response.choices.first?.delta.content {
                                    observer.onNext(content)
                                }
                            }
                        }
                    case let .failure(error):
                        observer.onError(error)
                    }
                case let .complete(completion):
                    if let error = completion.error {
                        observer.onError(error)
                    } else {
                        observer.onCompleted()
                    }
                }
            }
            
            return Disposables.create { request.cancel() }
        }
    }
    
    func upload<T: Decodable>(_ endpoint: OpenAIEndpoint, completion: @escaping (Result<T, Error>) -> Void) {
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
        
        guard let multipart = endpoint.multipart else {
            completion(.failure(OpenAIError.invalidRequestBody))
            return
        }
        
        session.upload(multipartFormData: multipart, to: url, method: endpoint.method, headers: headers)
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
