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

    func observeMessages(uid: String, conversationID: String) -> Observable<[ConversationMessage]> {
        Observable.create { observer in
            let listener = self.db.collection(uid).document(conversationID)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        observer.onError(error)
                        return
                    }

                    guard
                        let data = snapshot?.data(),
                        let rawMessages = data["messages"] as? [[String: Any]]
                    else {
                        observer.onNext([])
                        return
                    }

                    let messages = rawMessages.compactMap { dict -> ConversationMessage? in
                        guard
                            let roleStr = dict["role"] as? String,
                            let role = RoleType(rawValue: roleStr),
                            let text = dict["text"] as? String,
                            let timestamp = (dict["timestamp"] as? Timestamp)?.dateValue()
                        else { return nil }
                        return ConversationMessage(role: role, text: text, timestamp: timestamp)
                    }
                    observer.onNext(messages)
                }
            return Disposables.create { listener.remove() }
        }
    }
}
