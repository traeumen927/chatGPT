import Foundation
import FirebaseFirestore
import RxSwift

final class FirestoreUserPreferenceRepository: UserPreferenceRepository {
    private let db = Firestore.firestore()

    func fetch(uid: String) -> Single<UserPreference?> {
        Single.create { single in
            self.db.collection("preferences").document(uid).getDocument { doc, error in
                if let data = doc?.data() {
                    let topics = data["topics"] as? [String: Double] ?? [:]
                    let style = data["style"] as? [String: Double] ?? [:]
                    single(.success(UserPreference(topics: topics, style: style)))
                } else if let error = error {
                    single(.failure(error))
                } else {
                    single(.success(nil))
                }
            }
            return Disposables.create()
        }
    }

    func update(uid: String, tokens: [String]) -> Single<Void> {
        Single.create { single in
            let doc = self.db.collection("preferences").document(uid)
            doc.getDocument { snapshot, error in
                var topics = snapshot?.data()?["topics"] as? [String: Double] ?? [:]
                tokens.forEach { token in
                    topics[token, default: 0] += 1
                }
                doc.setData(["topics": topics], merge: true) { error in
                    if let error = error {
                        single(.failure(error))
                    } else {
                        single(.success(()))
                    }
                }
            }
            return Disposables.create()
        }
    }
}
