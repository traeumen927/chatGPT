import Foundation
import UIKit

struct OpenAIChatRequest: Encodable {
    struct URLInfo: Encodable {
        let url: String
    }
    struct Content: Encodable {
        let type: String
        let text: String?
        let imageURL: URLInfo?

        enum CodingKeys: String, CodingKey {
            case type
            case text
            case imageURL = "image_url"
        }
    }
    struct PayloadMessage: Encodable {
        let role: RoleType
        var content: [Content]
    }

    let model: String
    let messages: [PayloadMessage]
    let temperature: Double
    let stream: Bool

    init(model: String, messages: [Message], images: [UIImage], temperature: Double, stream: Bool) {
        var payloads: [PayloadMessage] = messages.map { msg in
            PayloadMessage(role: msg.role, content: [Content(type: "text", text: msg.content, imageURL: nil)])
        }
        if !images.isEmpty {
            let imageContents: [Content] = images.compactMap { image in
                guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
                let base64 = data.base64EncodedString()
                let info = URLInfo(url: "data:image/jpeg;base64,\(base64)")
                return Content(type: "image_url", text: nil, imageURL: info)
            }
            if let lastIndex = payloads.indices.last {
                payloads[lastIndex].content.append(contentsOf: imageContents)
            }
        }
        self.model = model
        self.messages = payloads
        self.temperature = temperature
        self.stream = stream
    }
}

struct Message: Codable {
    let role: RoleType
    let content: String
}
