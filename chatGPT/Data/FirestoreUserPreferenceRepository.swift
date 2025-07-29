import Foundation
import FirebaseFirestore
import RxSwift

final class FirestoreUserPreferenceRepository: UserPreferenceRepository {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

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
            let batch = self.db.batch()

            items.forEach { item in
                let doc = self.db.collection("preferences")
                    .document(uid)
                    .collection("items")
                    .document("\(item.key)_\(item.relation.rawValue)")
                let data: [String: Any] = [
                    "key": item.key,
                    "relation": item.relation.rawValue,
                    "updatedAt": item.updatedAt,
                    "count": FieldValue.increment(Int64(1))
                ]
                batch.setData(data, forDocument: doc, merge: true)
            }

            batch.commit { error in
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
