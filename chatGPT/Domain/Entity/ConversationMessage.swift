import Foundation

struct ConversationMessage: Codable {
    let role: RoleType
    let text: String
    let urls: [String]?
    let timestamp: Date
}
