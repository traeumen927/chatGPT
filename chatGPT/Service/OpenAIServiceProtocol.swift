import Foundation
import RxSwift

protocol OpenAIServiceProtocol {
    func request<T: Decodable>(_ endpoint: OpenAIEndpoint, completion: @escaping (Result<T, Error>) -> Void)
    func requestStream(_ endpoint: OpenAIEndpoint) -> Observable<String>
    func upload<T: Decodable>(_ endpoint: OpenAIEndpoint, completion: @escaping (Result<T, Error>) -> Void)
}
