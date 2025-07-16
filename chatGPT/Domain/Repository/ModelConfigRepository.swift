import Foundation
import RxSwift

protocol ModelConfigRepository {
    func fetchConfigs() -> Single<[ModelConfig]>
    func syncModels(with available: [OpenAIModel]) -> Single<[ModelConfig]>
}
