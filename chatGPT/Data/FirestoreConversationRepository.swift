import Foundation
import FirebaseFirestore
import RxSwift

final class FirestoreConversationRepository: ConversationRepository {
    private let db = Firestore.firestore()

    func createConversation(uid: String,
                            title: String,
                            question: String,
                            answer: String,
                            timestamp: Date) -> Single<String> {
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
                    single(.success(conversationID))
                }
            }
            return Disposables.create()
        }
    }

    func appendMessage(uid: String,
                       conversationID: String,
                       role: RoleType,
                       text: String,
                       timestamp: Date) -> Single<Void> {
        Single.create { single in
            let message: [String: Any] = [
                "role": role.rawValue,
                "text": text,
                "timestamp": Timestamp(date: timestamp)
            ]
            self.db.collection(uid)
                .document(conversationID)
                .updateData(["messages": FieldValue.arrayUnion([message])]) { error in
                    if let error = error {
                        single(.failure(error))
                    } else {
                        single(.success(()))
                    }
                }
            return Disposables.create()
        }
    }

    func fetchConversations(uid: String) -> Single<[ConversationSummary]> {
        Single.create { single in
            self.db.collection(uid).getDocuments { snapshot, error in
                if let error = error {
                    single(.failure(error))
                } else {
                    let conversations = snapshot?.documents.compactMap { doc -> ConversationSummary? in
                        guard let title = doc.data()["title"] as? String else { return nil }
                        return ConversationSummary(id: doc.documentID, title: title)
                    } ?? []
                    single(.success(conversations))
                }
            }
            return Disposables.create()
        }
    }
}
