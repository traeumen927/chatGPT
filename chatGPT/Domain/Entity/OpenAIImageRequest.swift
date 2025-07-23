import Foundation

struct OpenAIImageRequest: Encodable {
    let prompt: String
    let n: Int
    let size: String
}

struct OpenAIImageURL: Decodable {
    let url: String
}

struct OpenAIImageResponse: Decodable {
    let created: Int?
    let data: [OpenAIImageURL]
}
