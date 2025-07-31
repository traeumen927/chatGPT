import Foundation

struct PreferenceAnalysisResult: Codable {
    struct Preference: Codable {
        let key: String
        let relation: PreferenceRelation
    }
    let preferences: [Preference]
    let profile: UserProfile?
}
