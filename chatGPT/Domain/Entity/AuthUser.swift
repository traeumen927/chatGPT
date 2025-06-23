import Foundation

struct AuthUser: Equatable {
    let uid: String
    let displayName: String?
    let email: String?
    let photoURL: URL?
}
