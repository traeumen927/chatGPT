import Foundation
import RxSwift

final class FetchModelConfigsUseCase {
    private let configRepository: ModelConfigRepository
    private let openAIRepository: OpenAIRepository

    init(configRepository: ModelConfigRepository,
         openAIRepository: OpenAIRepository) {
        self.configRepository = configRepository
        self.openAIRepository = openAIRepository
    }

    func execute() -> Single<[ModelConfig]> {
        Self.wrap(openAIRepository)
            .flatMap { [weak self] models -> Single<[ModelConfig]> in
                guard let self else { return .just([]) }
                return self.configRepository.syncModels(with: models)
            }
    }

    private static func wrap(_ repo: OpenAIRepository) -> Single<[OpenAIModel]> {
        Single.create { single in
            repo.fetchAvailableModels { result in
                switch result {
                case .success(let models):
                    single(.success(models))
                case .failure(let error):
                    single(.failure(error))
                }
            }
            return Disposables.create()
        }
    }
}
