import Foundation
import RxSwift

final class UploadFilesUseCase {
    private let repository: FileStorageRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(repository: FileStorageRepository,
         getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.repository = repository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute(datas: [Data], extensions: [String]) -> Single<[String]> {
        guard let user = getCurrentUserUseCase.execute() else {
            return .error(ConversationError.noUser)
        }
        let uploads = datas.enumerated().map { index, data -> Single<String> in
            let ext = extensions[index]
            let path = "attachments/\(user.uid)/\(UUID().uuidString).\(ext)"
            return repository.upload(data: data, path: path)
                .map { $0.absoluteString }
        }
        return Single.zip(uploads)
    }
}
