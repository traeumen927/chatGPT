import Foundation
import RxSwift

enum UserInfoError: Error {
    case noUser
}

final class UpdateUserInfoUseCase {
    private let repository: UserInfoRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(repository: UserInfoRepository, getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.repository = repository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute(info: UserInfo) -> Single<Void> {
        guard let user = getCurrentUserUseCase.execute() else { return .error(UserInfoError.noUser) }
        return repository.update(uid: user.uid, attributes: info.attributes)
    }
}
