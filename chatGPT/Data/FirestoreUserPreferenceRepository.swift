import Foundation
import FirebaseFirestore
import RxSwift

final class FirestoreUserPreferenceRepository: UserPreferenceRepository {
    private let db = Firestore.firestore()

    func fetch(uid: String) -> Single<UserPreference?> {
        Single.create { single in
            self.db.collection("preferences").document(uid).collection("items").getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    let items: [PreferenceItem] = docs.compactMap { doc in
                        let data = doc.data()
                        guard
                            let key = data["key"] as? String,
                            let raw = data["relation"] as? String,
                            let relation = PreferenceRelation(rawValue: raw),
                            let updatedAt = data["updatedAt"] as? TimeInterval,
                            let count = data["count"] as? Int
                        else { return nil }
                        return PreferenceItem(key: key, relation: relation, updatedAt: updatedAt, count: count)
                    }
                    single(.success(UserPreference(items: items)))
                } else if let error = error {
                    single(.failure(error))
                } else {
                    single(.success(nil))
                }
            }
            return Disposables.create()
        }
    }

    func update(uid: String, items: [PreferenceItem]) -> Single<Void> {
        guard !items.isEmpty else { return .just(()) }
        return Single.create { single in
            let group = DispatchGroup()
            var firstError: Error?

            items.forEach { item in
                group.enter()
                let doc = self.db.collection("preferences")
                    .document(uid)
                    .collection("items")
                    .document("\(item.key)_\(item.relation.rawValue)")
                doc.getDocument { snapshot, error in
                    if let error = error { firstError = error; group.leave(); return }
                    let count = (snapshot?.data()? ["count"] as? Int ?? 0) + 1
                    let data: [String: Any] = [
                        "key": item.key,
                        "relation": item.relation.rawValue,
                        "count": count,
                        "updatedAt": item.updatedAt
                    ]
                    doc.setData(data) { err in
                        if let err = err { firstError = err }
                        group.leave()
                    }
                }
            }

            group.notify(queue: .main) {
                if let error = firstError {
                    single(.failure(error))
                } else {
                    single(.success(()))
                }
            }

            return Disposables.create()
        }
    }
}
