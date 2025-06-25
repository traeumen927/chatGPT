import Foundation
import RxSwift

final class FetchConversationMessagesUseCase {
    private let repository: ConversationRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(repository: ConversationRepository,
         getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.repository = repository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute(conversationID: String) -> Single<[ConversationMessage]> {
        guard let user = getCurrentUserUseCase.execute() else {
            return .error(ConversationError.noUser)
        }
        return repository.fetchMessages(uid: user.uid, conversationID: conversationID)
    }
}
