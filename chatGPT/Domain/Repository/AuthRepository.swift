import Foundation
import RxSwift


protocol AuthRepository {
    func observeAuthState() -> Observable<AuthUser?>
    func currentUser() -> AuthUser?
    func signOut() throws
}
