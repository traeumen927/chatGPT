import Foundation
import RxSwift

final class UpdateConversationTitleUseCase {
    private let repository: ConversationRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(repository: ConversationRepository,
         getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.repository = repository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute(conversationID: String, title: String) -> Single<Void> {
        guard let user = getCurrentUserUseCase.execute() else {
            return .error(ConversationError.noUser)
        }
        return repository.updateTitle(uid: user.uid,
                                      conversationID: conversationID,
                                      title: title)
    }
}
