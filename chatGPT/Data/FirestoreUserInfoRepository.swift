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
            self.db.collection("profiles").document(uid).collection("facts").getDocuments { snapshot, error in
                if let error = error {
                    single(.failure(error))
                    return
                }
                guard let docs = snapshot?.documents else {
                    single(.success(nil))
                    return
                }
                var attributes: [String: [UserFact]] = [:]
                for doc in docs {
                    let data = doc.data()
                    guard let name = data["name"] as? String,
                          let value = data["value"] as? String,
                          let count = data["count"] as? Int,
                          let first = data["firstMentioned"] as? TimeInterval,
                          let last = data["lastMentioned"] as? TimeInterval else { continue }
                    let fact = UserFact(value: value,
                                        count: count,
                                        firstMentioned: first,
                                        lastMentioned: last)
                    attributes[name, default: []].append(fact)
                }
                if attributes.isEmpty {
                    single(.success(nil))
                } else {
                    single(.success(UserInfo(attributes: attributes)))
                }
            }
            return Disposables.create()
        }
    }

    func observe(uid: String) -> Observable<UserInfo?> {
        Observable.create { observer in
            let listener = self.db.collection("profiles")
                .document(uid)
                .collection("facts")
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        observer.onError(error)
                        return
                    }
                    guard let docs = snapshot?.documents else {
                        observer.onNext(nil)
                        return
                    }
                    var attributes: [String: [UserFact]] = [:]
                    for doc in docs {
                        let data = doc.data()
                        guard let name = data["name"] as? String,
                              let value = data["value"] as? String,
                              let count = data["count"] as? Int,
                              let first = data["firstMentioned"] as? TimeInterval,
                              let last = data["lastMentioned"] as? TimeInterval else { continue }
                        let fact = UserFact(value: value,
                                            count: count,
                                            firstMentioned: first,
                                            lastMentioned: last)
                        attributes[name, default: []].append(fact)
                    }
                    if attributes.isEmpty {
                        observer.onNext(nil)
                    } else {
                        observer.onNext(UserInfo(attributes: attributes))
                    }
                }
            return Disposables.create { listener.remove() }
        }
    }

    func update(uid: String, attributes: [String: [UserFact]]) -> Single<Void> {
        guard !attributes.isEmpty else { return .just(()) }
        let tasks = attributes.flatMap { name, facts in
            facts.map { fact in updateFact(uid: uid, name: name, fact: fact) }
        }
        return Single.zip(tasks) { _ in () }
    }

    private func updateFact(uid: String, name: String, fact: UserFact) -> Single<Void> {
        Single.create { single in
            let canonical = fact.value.factIdentifier()
            let docPath = "profiles/\(uid)/facts/\(canonical)"
            let ref = self.db.document(docPath)
            ref.getDocument { snapshot, error in
                if let error {
                    single(.failure(error))
                    return
                }
                if snapshot?.exists == true {
                    ref.updateData([
                        "count": FieldValue.increment(Int64(fact.count)),
                        "lastMentioned": fact.lastMentioned
                    ]) { error in
                        if let error { single(.failure(error)) }
                        else { single(.success(())) }
                    }
                } else {
                    let data: [String: Any] = [
                        "name": name,
                        "value": fact.value,
                        "canonicalValue": canonical,
                        "count": fact.count,
                        "firstMentioned": fact.firstMentioned,
                        "lastMentioned": fact.lastMentioned
                    ]
                    ref.setData(data) { error in
                        if let error { single(.failure(error)) }
                        else { single(.success(())) }
                    }
                }
            }
            return Disposables.create()
        }
    }
}
