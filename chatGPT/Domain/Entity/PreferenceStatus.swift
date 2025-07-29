import Foundation

struct PreferenceStatus: Codable {
    let key: String
    var currentRelation: PreferenceRelation
    var updatedAt: TimeInterval
    var previousRelation: PreferenceRelation?
    var changedAt: TimeInterval?
}
