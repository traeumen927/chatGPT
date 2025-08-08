import Foundation
import RxSwift

protocol OpenAIServiceProtocol {
    @discardableResult
    func request<T: Decodable>(_ endpoint: OpenAIEndpoint, completion: @escaping (Result<T, Error>) -> Void) -> CancelToken
    func requestStream(_ endpoint: OpenAIEndpoint) -> Observable<String>
    func upload<T: Decodable>(_ endpoint: OpenAIEndpoint, completion: @escaping (Result<T, Error>) -> Void)
}
