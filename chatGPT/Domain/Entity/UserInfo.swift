import Foundation

struct UserInfo: Codable, Equatable {
    var attributes: [String: [UserFact]]
}
