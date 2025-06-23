import Foundation
import FirebaseAuth
import RxSwift

final class FirebaseAuthRepository: AuthRepository {
    func observeAuthState() -> Observable<User?> {
        Observable.create { observer in
            let handle = Auth.auth().addStateDidChangeListener { _, user in
                observer.onNext(user)
            }
            return Disposables.create {
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
