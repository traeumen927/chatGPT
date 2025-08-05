import Foundation
import RxSwift

final class FetchUserInfoUseCase {
    private let repository: UserInfoRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(repository: UserInfoRepository, getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.repository = repository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute() -> Single<UserInfo?> {
        guard let user = getCurrentUserUseCase.execute() else { return .just(nil) }
        return repository.fetch(uid: user.uid)
    }

    func observe() -> Observable<UserInfo?> {
        guard let user = getCurrentUserUseCase.execute() else { return .just(nil) }
        return repository.observe(uid: user.uid)
    }
}
