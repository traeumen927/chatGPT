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
    func fetchMessages(uid: String, conversationID: String) -> Single<[ConversationMessage]>
    func observeConversations(uid: String) -> Observable<[ConversationSummary]>
    func updateTitle(uid: String, conversationID: String, title: String) -> Single<Void>
    func deleteConversation(uid: String, conversationID: String) -> Single<Void>
}
