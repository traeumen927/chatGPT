import Foundation

struct Chat {
    let id: String
    let title: String
    var messages: [ChatRecordMessage]
    let createdAt: Date
}

struct ChatRecordMessage {
    let id: String
    let text: String
    let isUser: Bool
    let createdAt: Date
}
