import Foundation
import RxSwift

final class SaveConversationUseCase {
    private let repository: ConversationRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(repository: ConversationRepository,
         getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.repository = repository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute(title: String,
                 question: String,
                 answer: String,
                 timestamp: Date = Date()) -> Single<Void> {
        guard let user = getCurrentUserUseCase.execute() else {
            return .error(ConversationError.noUser)
        }
        return repository.createConversation(uid: user.uid,
                                             title: title,
                                             question: question,
                                             answer: answer,
                                             timestamp: timestamp)
    }
}

enum ConversationError: Error {
    case noUser
}
