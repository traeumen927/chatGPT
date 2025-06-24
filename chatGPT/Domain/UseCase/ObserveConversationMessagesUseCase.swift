import Foundation
import RxSwift

final class ObserveConversationMessagesUseCase {
    private let repository: ConversationRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(repository: ConversationRepository,
         getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.repository = repository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute(conversationID: String) -> Observable<[ConversationMessage]> {
        guard let user = getCurrentUserUseCase.execute() else {
            return .error(ConversationError.noUser)
        }
        return repository.observeMessages(uid: user.uid, conversationID: conversationID)
    }
}
