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
        configRepository.fetchConfigs()
            .flatMap { [weak self] configs -> Single<[ModelConfig]> in
                guard let self else { return .just(configs) }
                return Self.wrap(self.openAIRepository)
                    .map { available in
                        let set = Set(available.map { $0.id })
                        return configs.filter { set.contains($0.modelId) }
                    }
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
