import Foundation

struct AuthUser: Equatable {
    let uid: String
    let displayName: String?
    let photoURL: URL?
}
