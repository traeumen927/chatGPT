import Foundation
import RxSwift

enum UserProfileError: Error {
    case noUser
}

final class UpdateUserProfileUseCase {
    private let repository: UserProfileRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(repository: UserProfileRepository, getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.repository = repository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute(profile: UserProfile) -> Single<Void> {
        guard let user = getCurrentUserUseCase.execute() else { return .error(UserProfileError.noUser) }
        return repository.update(uid: user.uid, profile: profile)
    }
}
