import Foundation
import RxSwift

protocol ModelConfigRepository {
    func fetchConfigs() -> Single<[ModelConfig]>
    func syncConfigs(with models: [OpenAIModel]) -> Single<[ModelConfig]>
}
