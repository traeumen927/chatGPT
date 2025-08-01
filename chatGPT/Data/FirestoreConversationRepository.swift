import Foundation
import FirebaseFirestore
import RxSwift

final class FirestoreConversationRepository: ConversationRepository {
    private let db = Firestore.firestore()

    private func userCollection(_ uid: String) -> CollectionReference {
        db.collection("conversations").document(uid).collection("items")
    }
    private var listener: ListenerRegistration?
    private var currentUID: String?
    private let subject = BehaviorSubject<[ConversationSummary]>(value: [])

    func createConversation(uid: String,
                            title: String,
                            question: String,
                            questionURLs: [String],
                            answer: String,
                            answerURLs: [String],
                            timestamp: Date) -> Single<String> {
        Single.create { single in
            let conversationID = UUID().uuidString
            let data: [String: Any] = [
                "title": title,
                "timestamp": Timestamp(date: timestamp),
                "messages": [
                    [
                        "role": "user",
                        "text": question,
                        "urls": questionURLs,
                        "timestamp": Timestamp(date: timestamp)
                    ],
                    [
                        "role": "assistant",
                        "text": answer,
                        "urls": answerURLs,
                        "timestamp": Timestamp(date: timestamp)
                    ]
                ]
            ]
            self.userCollection(uid).document(conversationID).setData(data) { error in
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
                       urls: [String],
                       timestamp: Date) -> Single<Void> {
        Single.create { single in
            let message: [String: Any] = [
                "role": role.rawValue,
                "text": text,
                "urls": urls,
                "timestamp": Timestamp(date: timestamp)
            ]
            self.userCollection(uid)
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
            self.userCollection(uid).getDocuments { snapshot, error in
                if let error = error {
                    single(.failure(error))
                } else {
                    let conversations = snapshot?.documents.compactMap { doc -> ConversationSummary? in
                        guard let title = doc.data()["title"] as? String else { return nil }
                        let timestamp = (doc.data()["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                        return ConversationSummary(id: doc.documentID,
                                                    title: title,
                                                    timestamp: timestamp)
                    } ?? []
                    single(.success(conversations))
                }
            }
            return Disposables.create()
        }
    }

    func observeConversations(uid: String) -> Observable<[ConversationSummary]> {
        if currentUID != uid {
            listener?.remove()
            currentUID = uid
            listener = userCollection(uid).addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let docs = snapshot?.documents {
                    let items = docs.compactMap { doc -> ConversationSummary? in
                        guard let title = doc.data()["title"] as? String else { return nil }
                        let timestamp = (doc.data()["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                        return ConversationSummary(id: doc.documentID,
                                                    title: title,
                                                    timestamp: timestamp)
                    }
                    self.subject.onNext(items)
                } else if let error = error {
                    self.subject.onError(error)
                }
            }
        }
        return subject.asObservable()
    }

    func fetchMessages(uid: String, conversationID: String) -> Single<[ConversationMessage]> {
        Single.create { single in
            self.userCollection(uid).document(conversationID).getDocument { document, error in
                if let data = document?.data(),
                   let rawMessages = data["messages"] as? [[String: Any]] {
                    let messages = rawMessages.compactMap { dict -> ConversationMessage? in
                        guard let roleStr = dict["role"] as? String,
                              let role = RoleType(rawValue: roleStr),
                              let text = dict["text"] as? String else { return nil }
                        let timestamp = (dict["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                        let urls = dict["urls"] as? [String] ?? []
                        return ConversationMessage(role: role, text: text, urls: urls, timestamp: timestamp)
                    }
                    single(.success(messages))
                } else if let error = error {
                    single(.failure(error))
                } else {
                    single(.success([]))
                }
            }
            return Disposables.create()
        }
    }

    func updateTitle(uid: String, conversationID: String, title: String) -> Single<Void> {
        Single.create { single in
            self.userCollection(uid).document(conversationID).updateData(["title": title]) { error in
                if let error = error {
                    single(.failure(error))
                } else {
                    single(.success(()))
                }
            }
            return Disposables.create()
        }
    }

    func deleteConversation(uid: String, conversationID: String) -> Single<Void> {
        Single.create { single in
            self.userCollection(uid).document(conversationID).delete { error in
                if let error = error {
                    single(.failure(error))
                } else {
                    single(.success(()))
                }
            }
            return Disposables.create()
        }
    }

    deinit {
        listener?.remove()
    }
}
