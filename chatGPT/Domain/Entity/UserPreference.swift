import Foundation

enum PreferenceRelation: String, Codable {
    case like
    case dislike
    case want
    case avoid
}

struct PreferenceItem: Codable {
    let key: String
    let relation: PreferenceRelation
    let updatedAt: TimeInterval
    var count: Int
}

struct UserPreference: Codable {
    var items: [PreferenceItem]
}
