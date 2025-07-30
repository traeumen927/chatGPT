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
                    let name = data["displayName"] as? String
                    var url: URL?
                    if let str = data["photoURL"] as? String {
                        url = URL(string: str)
                    }
                    single(.success(UserProfile(displayName: name, photoURL: url)))
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
            if let name = profile.displayName { data["displayName"] = name }
            if let url = profile.photoURL { data["photoURL"] = url.absoluteString }
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
