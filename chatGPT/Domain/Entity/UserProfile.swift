import Foundation

struct UserProfile: Codable, Equatable {
    var displayName: String?
    var photoURL: URL?
    var age: Int?
    var gender: String?
    var job: String?
    var interest: String?
}
