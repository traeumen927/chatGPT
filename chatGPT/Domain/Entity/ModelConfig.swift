import Foundation

struct ModelConfig: Decodable {
    let displayName: String
    let modelId: String
    let description: String
    let vision: Bool
    let enabled: Bool

    enum CodingKeys: String, CodingKey {
        case displayName = "name"
        case modelId = "model"
        case description
        case vision
        case enabled = "enable"
    }

    var openAIModel: OpenAIModel {
        OpenAIModel(id: modelId)
    }
}
