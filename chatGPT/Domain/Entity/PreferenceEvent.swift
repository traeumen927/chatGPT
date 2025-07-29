import Foundation

struct PreferenceEvent: Codable {
    let key: String
    let relation: PreferenceRelation
    let timestamp: TimeInterval
}
