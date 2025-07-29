import Foundation
import RxSwift

final class DeletePreferenceStatusUseCase {
    private let repository: PreferenceStatusRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(repository: PreferenceStatusRepository,
         getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.repository = repository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute(key: String) -> Single<Void> {
        guard let user = getCurrentUserUseCase.execute() else {
            return .error(PreferenceError.noUser)
        }
        return repository.delete(uid: user.uid, key: key)
    }
}
