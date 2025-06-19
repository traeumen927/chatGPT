import Foundation
import FirebaseFirestore
import FirebaseAuth
import RxSwift

struct ChatDTO: Codable {
    let id: String
    let title: String
    let createdAt: Date
}

struct ChatMessageDTO: Codable {
    let id: String
    let text: String
    let isUser: Bool
    let createdAt: Date
}

final class FirebaseChatDataSource {
    private let db = Firestore.firestore()

    private var userID: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    func fetchChats() -> Observable<[ChatDTO]> {
        Observable.create { observer in
            self.db.collection("users").document(self.userID)
                .collection("chats")
                .order(by: "createdAt", descending: true)
                .getDocuments { snapshot, error in
                    if let error = error {
                        observer.onError(error)
                    } else {
                        let chats = snapshot?.documents.compactMap { try? $0.data(as: ChatDTO.self) } ?? []
                        observer.onNext(chats)
                        observer.onCompleted()
                    }
                }
            return Disposables.create()
        }
    }

    func createChat(title: String) -> Observable<ChatDTO> {
        Observable.create { observer in
            let ref = self.db.collection("users").document(self.userID)
                .collection("chats").document()
            let dto = ChatDTO(id: ref.documentID, title: title, createdAt: Date())
            do {
                try ref.setData(from: dto) { error in
                    if let error = error {
                        observer.onError(error)
                    } else {
                        observer.onNext(dto)
                        observer.onCompleted()
                    }
                }
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    func appendMessage(chatID: String, message: ChatMessageDTO) -> Observable<Void> {
        Observable.create { observer in
            let ref = self.db.collection("users").document(self.userID)
                .collection("chats").document(chatID)
                .collection("messages").document(message.id)
            do {
                try ref.setData(from: message) { error in
                    if let error = error {
                        observer.onError(error)
                    } else {
                        observer.onNext(())
                        observer.onCompleted()
                    }
                }
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }
}
