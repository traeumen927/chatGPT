import Foundation
import RxSwift

final class UpdatePreferenceStatusUseCase {
    private let repository: PreferenceStatusRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(repository: PreferenceStatusRepository,
         getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.repository = repository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute(status: PreferenceStatus) -> Single<Void> {
        guard let user = getCurrentUserUseCase.execute() else {
            return .error(PreferenceError.noUser)
        }
        return repository.update(uid: user.uid, status: status)
    }
}
