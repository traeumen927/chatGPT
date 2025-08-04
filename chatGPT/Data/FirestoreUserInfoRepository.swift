import Foundation
import FirebaseFirestore
import RxSwift

final class FirestoreUserInfoRepository: UserInfoRepository {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func fetch(uid: String) -> Single<UserInfo?> {
        .just(nil)
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
            let docPath = "profiles/\(uid)/facts/\(name)-\(fact.value)"
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
