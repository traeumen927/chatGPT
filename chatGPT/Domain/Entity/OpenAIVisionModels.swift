import Foundation

struct VisionContent: Encodable {
    let type: String
    let text: String?
    let imageURL: String?

    enum CodingKeys: String, CodingKey {
        case type, text
        case imageURL = "image_url"
    }
}

struct VisionMessage: Encodable {
    let role: RoleType
    let content: [VisionContent]
}

struct OpenAIVisionChatRequest: Encodable {
    let model: String
    let messages: [VisionMessage]
    let temperature: Double
    let stream: Bool
}
