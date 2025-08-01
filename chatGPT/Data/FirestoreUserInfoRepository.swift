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
            self.db.collection("userInfo").document(uid).getDocument { snapshot, error in
                if let data = snapshot?.data() {
                    var attributes: [String: String] = [:]
                    data.forEach { key, value in
                        if let str = value as? String {
                            attributes[key] = str
                        } else {
                            attributes[key] = "\(value)"
                        }
                    }
                    single(.success(UserInfo(attributes: attributes)))
                } else if let error = error {
                    single(.failure(error))
                } else {
                    single(.success(nil))
                }
            }
            return Disposables.create()
        }
    }

    func update(uid: String, attributes: [String: String]) -> Single<Void> {
        guard !attributes.isEmpty else { return .just(()) }
        return Single.create { single in
            var data: [String: Any] = [:]
            attributes.forEach { key, value in
                data[key] = value
            }
            self.db.collection("userInfo").document(uid).setData(data, merge: true) { error in
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
