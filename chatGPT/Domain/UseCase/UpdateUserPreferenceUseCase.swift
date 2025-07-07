import Foundation
import RxSwift

final class UpdateUserPreferenceUseCase {
    private let repository: UserPreferenceRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(repository: UserPreferenceRepository, getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.repository = repository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute(prompt: String) -> Single<Void> {
        guard let user = getCurrentUserUseCase.execute() else {
            return .error(PreferenceError.noUser)
        }
        let tokens = prompt.split { $0.isWhitespace || $0.isPunctuation }
            .map { String($0).lowercased() }
        return repository.update(uid: user.uid, tokens: tokens)
    }
}
