import Foundation
import RxSwift

final class FetchConversationsUseCase {
    private let repository: ConversationRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(repository: ConversationRepository,
         getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.repository = repository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute() -> Single<[ConversationSummary]> {
        guard let user = getCurrentUserUseCase.execute() else {
            return .error(ConversationError.noUser)
        }
        return repository.fetchConversations(uid: user.uid)
            .map { list in
                list.sorted { $0.timestamp > $1.timestamp }
            }
    }
}
