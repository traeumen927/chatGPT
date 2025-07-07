import Foundation
import RxSwift

final class FetchUserPreferenceUseCase {
    private let repository: UserPreferenceRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(repository: UserPreferenceRepository, getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.repository = repository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute() -> Single<UserPreference?> {
        guard let user = getCurrentUserUseCase.execute() else {
            return .just(nil)
        }
        return repository.fetch(uid: user.uid)
    }
}
