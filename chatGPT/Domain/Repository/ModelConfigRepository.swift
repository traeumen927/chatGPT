import Foundation
import RxSwift

protocol ModelConfigRepository {
    func fetchConfigs() -> Single<[ModelConfig]>
}
