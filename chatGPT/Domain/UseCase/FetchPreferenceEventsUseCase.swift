import Foundation
import RxSwift

final class FetchPreferenceEventsUseCase {
    private let repository: PreferenceEventRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(repository: PreferenceEventRepository,
         getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.repository = repository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute() -> Single<[PreferenceEvent]> {
        guard let user = getCurrentUserUseCase.execute() else {
            return .just([])
        }
        return repository.fetch(uid: user.uid)
    }
}
