import Foundation
import FirebaseFirestore
import RxSwift

final class FirestorePreferenceEventRepository: PreferenceEventRepository {
    private let db = Firestore.firestore()

    func add(uid: String, events: [PreferenceEvent]) -> Single<Void> {
        guard !events.isEmpty else { return .just(()) }
        return Single.create { single in
            let batch = self.db.batch()
            let collection = self.db.collection("preferences").document(uid).collection("events")
            events.forEach { event in
                let doc = collection.document()
                let data: [String: Any] = [
                    "key": event.key,
                    "relation": event.relation.rawValue,
                    "timestamp": event.timestamp
                ]
                batch.setData(data, forDocument: doc)
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

    func fetch(uid: String) -> Single<[PreferenceEvent]> {
        Single.create { single in
            self.db.collection("preferences").document(uid).collection("events").getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    let events: [PreferenceEvent] = docs.compactMap { doc in
                        let data = doc.data()
                        guard
                            let key = data["key"] as? String,
                            let raw = data["relation"] as? String,
                            let relation = PreferenceRelation(rawValue: raw),
                            let timestamp = data["timestamp"] as? TimeInterval
                        else { return nil }
                        return PreferenceEvent(key: key, relation: relation, timestamp: timestamp)
                    }
                    single(.success(events))
                } else if let error = error {
                    single(.failure(error))
                } else {
                    single(.success([]))
                }
            }
            return Disposables.create()
        }
    }
}
