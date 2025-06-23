import Foundation
import FirebaseFirestore
import RxSwift

final class FirestoreConversationRepository: ConversationRepository {
    private let db = Firestore.firestore()

    func createConversation(uid: String,
                            title: String,
                            question: String,
                            answer: String,
                            timestamp: Date) -> Single<Void> {
        Single.create { single in
            let conversationID = UUID().uuidString
            let data: [String: Any] = [
                "title": title,
                "messages": [
                    [
                        "role": "user",
                        "text": question,
                        "timestamp": Timestamp(date: timestamp)
                    ],
                    [
                        "role": "assistant",
                        "text": answer,
                        "timestamp": Timestamp(date: timestamp)
                    ]
                ]
            ]
            self.db.collection(uid).document(conversationID).setData(data) { error in
                if let error = error {
                    single(.failure(error))
                } else {
                    single(.success(()))
                }
            }
            return Disposables.create()
        }
    }
}
