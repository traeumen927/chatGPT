import Foundation

struct PreferenceEvent: Codable {
    var id: String?
    let key: String
    let relation: PreferenceRelation
    let timestamp: TimeInterval

    init(id: String? = nil, key: String, relation: PreferenceRelation, timestamp: TimeInterval) {
        self.id = id
        self.key = key
        self.relation = relation
        self.timestamp = timestamp
    }
}
