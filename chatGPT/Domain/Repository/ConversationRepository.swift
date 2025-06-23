import Foundation
import RxSwift

protocol ConversationRepository {
    func createConversation(uid: String,
                            title: String,
                            question: String,
                            answer: String,
                            timestamp: Date) -> Single<Void>
}
