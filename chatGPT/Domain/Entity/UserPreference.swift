import Foundation

struct PreferenceRelation: RawRepresentable, Codable, Hashable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }


    var sanitized: String {
        rawValue
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
    }
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
