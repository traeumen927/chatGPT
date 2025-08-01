import Foundation
import FirebaseFirestore
import RxSwift

final class FirestoreUserInfoRepository: UserInfoRepository {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func fetch(uid: String) -> Single<UserInfo?> {
        Single.create { single in
            self.db.collection("profiles")
                .document(uid)
                .collection("facts")
                .getDocuments { snapshot, error in
                    if let docs = snapshot?.documents {
                        var result: [String: [UserFact]] = [:]
                        for doc in docs {
                            let data = doc.data()
                            guard
                                let name = data["name"] as? String,
                                let value = data["value"] as? String,
                                let count = data["count"] as? Int,
                                let first = data["firstMentioned"] as? TimeInterval,
                                let last = data["lastMentioned"] as? TimeInterval
                            else { continue }
                            let fact = UserFact(value: value, count: count, firstMentioned: first, lastMentioned: last)
                            var arr = result[name] ?? []
                            arr.append(fact)
                            result[name] = arr
                        }
                        single(.success(UserInfo(attributes: result)))
                    } else if let error = error {
                        single(.failure(error))
                    } else {
                        single(.success(nil))
                    }
                }
            return Disposables.create()
        }
    }

    func update(uid: String, attributes: [String: [UserFact]]) -> Single<Void> {
        guard !attributes.isEmpty else { return .just(()) }
        return Single.create { single in
            let batch = self.db.batch()
            for (name, facts) in attributes {
                for fact in facts {
                    let doc = self.db.collection("profiles")
                        .document(uid)
                        .collection("facts")
                        .document("\(name)-\(fact.value)")
                    let data: [String: Any] = [
                        "name": name,
                        "value": fact.value,
                        "count": fact.count,
                        "firstMentioned": fact.firstMentioned,
                        "lastMentioned": fact.lastMentioned
                    ]
                    batch.setData(data, forDocument: doc, merge: true)
                }
            }
            batch.commit { error in
                if let error = error { single(.failure(error)) }
                else { single(.success(())) }
            }
            return Disposables.create()
        }
    }
}
