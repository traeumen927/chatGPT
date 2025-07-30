import Foundation
import RxSwift

final class FetchUserProfileUseCase {
    private let repository: UserProfileRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(repository: UserProfileRepository, getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.repository = repository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute() -> Single<UserProfile?> {
        guard let user = getCurrentUserUseCase.execute() else { return .just(nil) }
        return repository.fetch(uid: user.uid)
    }
}
