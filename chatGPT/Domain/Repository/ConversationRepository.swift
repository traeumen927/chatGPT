import Foundation
import RxSwift

protocol ConversationRepository {
    func createConversation(uid: String,
                            title: String,
                            question: String,
                            answer: String,
                            timestamp: Date) -> Single<String>
    func appendMessage(uid: String,
                       conversationID: String,
                       role: RoleType,
                       text: String,
                       timestamp: Date) -> Single<Void>
    func fetchConversations(uid: String) -> Single<[ConversationSummary]>
}
