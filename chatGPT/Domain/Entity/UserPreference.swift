import Foundation

struct UserPreference: Codable {
    var topics: [String: Double]
    var style: [String: Double]
}
