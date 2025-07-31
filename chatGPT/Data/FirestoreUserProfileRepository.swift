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
                    let age = data["age"] as? Int
                    let gender = data["gender"] as? String
                    let job = data["job"] as? String
                    let interest = data["interest"] as? String
                    single(.success(UserProfile(displayName: name,
                                              photoURL: url,
                                              age: age,
                                              gender: gender,
                                              job: job,
                                              interest: interest)))
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
            if let age = profile.age { data["age"] = age }
            if let gender = profile.gender { data["gender"] = gender }
            if let job = profile.job { data["job"] = job }
            if let interest = profile.interest { data["interest"] = interest }
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
