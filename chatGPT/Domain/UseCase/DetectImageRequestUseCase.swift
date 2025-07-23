import Foundation
import RxSwift

final class DetectImageRequestUseCase {
    private let repository: OpenAIRepository

    init(repository: OpenAIRepository) {
        self.repository = repository
    }

    func execute(prompt: String) -> Single<Bool> {
        repository.detectImageIntent(prompt: prompt)
            .catchAndReturn(false)
    }
}
