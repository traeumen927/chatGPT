import Foundation
import RxSwift

final class FetchPreferenceStatusUseCase {
    private let repository: PreferenceStatusRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(repository: PreferenceStatusRepository,
         getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.repository = repository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute() -> Single<[PreferenceStatus]> {
        guard let user = getCurrentUserUseCase.execute() else {
            return .just([])
        }
        return repository.fetch(uid: user.uid)
    }
}
