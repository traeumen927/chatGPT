import Foundation

struct ConversationMessage: Codable {
    let role: RoleType
    let text: String
    let timestamp: Date
    let files: [String]
}
