import Foundation
import RxSwift
import FirebaseAuth

protocol AuthRepository {
    func observeAuthState() -> Observable<User?>
    func signOut() throws
}
