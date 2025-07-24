import Foundation
import RxSwift

final class AppendMessageUseCase {
    private let repository: ConversationRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(repository: ConversationRepository,
         getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.repository = repository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute(conversationID: String,
                 role: RoleType,
                 text: String,
                 urls: [String] = [],
                 timestamp: Date = Date()) -> Single<Void> {
        guard let user = getCurrentUserUseCase.execute() else {
            return .error(ConversationError.noUser)
        }
        return repository.appendMessage(uid: user.uid,
                                        conversationID: conversationID,
                                        role: role,
                                        text: text,
                                        urls: urls,
                                        timestamp: timestamp)
    }
}
