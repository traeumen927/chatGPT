import Foundation

struct UserFact: Codable, Equatable {
    var value: String
    var count: Int
    var firstMentioned: TimeInterval
    var lastMentioned: TimeInterval
}
