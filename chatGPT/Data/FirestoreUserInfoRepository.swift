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
        return Single.create { single in
            let batch = self.db.batch()
            for (name, facts) in attributes {
                for fact in facts {
                    let docPath = "profiles/\(uid)/facts/\(name)-\(fact.value)"
                    let ref = self.db.document(docPath)
                    let data: [String: Any] = [
                        "name": name,
                        "value": fact.value,
                        "count": fact.count,
                        "firstMentioned": fact.firstMentioned,
                        "lastMentioned": fact.lastMentioned
                    ]
                    batch.setData(data, forDocument: ref, merge: true)
                }
            }
            batch.commit { error in
                if let error { single(.failure(error)) }
                else { single(.success(())) }
            }
            return Disposables.create()
        }
    }
}
