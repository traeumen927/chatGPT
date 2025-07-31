import Foundation
import FirebaseFirestore
import RxSwift

final class FirestorePreferenceStatusRepository: PreferenceStatusRepository {
    private let db = Firestore.firestore()

    func fetch(uid: String) -> Single<[PreferenceStatus]> {
        Single.create { single in
            self.db.collection("preferences").document(uid).collection("status").getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    let statuses: [PreferenceStatus] = docs.compactMap { doc in
                        let data = doc.data()
                        guard
                            let key = data["key"] as? String,
                            let raw = data["currentRelation"] as? String
                        else { return nil }
                        let relation = PreferenceRelation(rawValue: raw)
                        let updated: TimeInterval
                        if let ts = data["updatedAt"] as? Timestamp {
                            updated = ts.dateValue().timeIntervalSince1970
                        } else if let interval = data["updatedAt"] as? TimeInterval {
                            updated = interval
                        } else {
                            updated = Date().timeIntervalSince1970
                        }
                        let prevRaw = data["previousRelation"] as? String
                        let prev = prevRaw.map { PreferenceRelation(rawValue: $0) }
                        let changedAt = data["changedAt"] as? TimeInterval
                        return PreferenceStatus(key: key,
                                                currentRelation: relation,
                                                updatedAt: updated,
                                                previousRelation: prev,
                                                changedAt: changedAt)
                    }
                    single(.success(statuses))
                } else if let error = error {
                    single(.failure(error))
                } else {
                    single(.success([]))
                }
            }
            return Disposables.create()
        }
    }

    func update(uid: String, status: PreferenceStatus) -> Single<Void> {
        Single.create { single in
            let doc = self.db.collection("preferences")
                .document(uid)
                .collection("status")
                .document(status.key)
            var data: [String: Any] = [
                "key": status.key,
                "currentRelation": status.currentRelation.rawValue,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            if let prev = status.previousRelation {
                data["previousRelation"] = prev.rawValue
            }
            if let changed = status.changedAt {
                data["changedAt"] = changed
            }
            doc.setData(data, merge: true) { error in
                if let error = error {
                    single(.failure(error))
                } else {
                    single(.success(()))
                }
            }
            return Disposables.create()
        }
    }

    func delete(uid: String, key: String) -> Single<Void> {
        Single.create { single in
            self.db.collection("preferences")
                .document(uid)
                .collection("status")
                .document(key)
                .delete { error in
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
