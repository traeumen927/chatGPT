import Foundation
import RxSwift

final class DeletePreferenceEventUseCase {
    private let repository: PreferenceEventRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(repository: PreferenceEventRepository,
         getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.repository = repository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute(eventID: String) -> Single<Void> {
        guard let user = getCurrentUserUseCase.execute() else {
            return .error(PreferenceError.noUser)
        }
        return repository.delete(uid: user.uid, eventID: eventID)
    }
}
