import Foundation
import FirebaseFirestore
import RxSwift

final class FirestoreUserProfileRepository: UserProfileRepository {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func fetch(uid: String) -> Single<UserProfile?> {
        Single.create { single in
            self.db.collection("profiles").document(uid).getDocument { snapshot, error in
                if let data = snapshot?.data() {
                    var attributes: [String: String] = [:]
                    data.forEach { key, value in
                        if let str = value as? String {
                            attributes[key] = str
                        } else {
                            attributes[key] = "\(value)"
                        }
                    }
                    single(.success(UserProfile(attributes: attributes)))
                } else if let error = error {
                    single(.failure(error))
                } else {
                    single(.success(nil))
                }
            }
            return Disposables.create()
        }
    }

    func update(uid: String, profile: UserProfile) -> Single<Void> {
        Single.create { single in
            var data: [String: Any] = [:]
            profile.attributes.forEach { key, value in
                data[key] = value
            }
            self.db.collection("profiles").document(uid).setData(data, merge: true) { error in
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
