import Foundation
import RxSwift

final class UploadFilesUseCase {
    private let repository: FileRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(repository: FileRepository, getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.repository = repository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute(datas: [Data]) -> Single<[URL]> {
        guard let user = getCurrentUserUseCase.execute() else {
            return .error(ConversationError.noUser)
        }
        return repository.uploadFiles(uid: user.uid, datas: datas)
    }
}
