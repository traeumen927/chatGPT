import Foundation
import RxSwift

final class FetchUserInfoUseCase {
    private let repository: UserInfoRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let memoryStore: UserMemoryStore

    init(repository: UserInfoRepository,
         getCurrentUserUseCase: GetCurrentUserUseCase,
         memoryStore: UserMemoryStore = .shared) {
        self.repository = repository
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.memoryStore = memoryStore
    }

    func execute() -> Single<UserInfo?> {
        guard let user = getCurrentUserUseCase.execute() else { return .just(nil) }
        return repository.fetch(uid: user.uid)
    }

    func observe() -> Observable<UserInfo?> {
        guard let user = getCurrentUserUseCase.execute() else { return .just(nil) }
        let since = memoryStore.latestTimestamp
        let observable = repository.observe(uid: user.uid, since: since)
        memoryStore.bind(observable)
        return memoryStore.asObservable()
    }
}
