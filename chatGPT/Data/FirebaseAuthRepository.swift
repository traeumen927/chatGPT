import Foundation
import FirebaseAuth
import RxSwift

final class FirebaseAuthRepository: AuthRepository {
    func observeAuthState() -> Observable<AuthUser?> {
        Observable.create { observer in
            let handle = Auth.auth().addStateDidChangeListener { _, user in
                if let user = user {
                    observer.onNext(AuthUser(uid: user.uid,
                                            displayName: user.displayName,
                                            email: user.email,
                                            photoURL: user.photoURL))
                } else {
                    observer.onNext(nil)
                }
            }
            return Disposables.create {
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }

    func currentUser() -> AuthUser? {
        guard let user = Auth.auth().currentUser else { return nil }
        return AuthUser(uid: user.uid,
                        displayName: user.displayName,
                        email: user.email,
                        photoURL: user.photoURL)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
