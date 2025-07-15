import Foundation

struct ModelConfig: Decodable {
    let displayName: String
    let modelId: String
    let description: String
    let vision: Bool
    let enable: Bool
    let deprecated: Bool

    enum CodingKeys: String, CodingKey {
        case displayName = "name"
        case modelId = "model"
        case description
        case vision
        case enable
        case deprecated
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayName = try container.decode(String.self, forKey: .displayName)
        modelId = try container.decode(String.self, forKey: .modelId)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        vision = try container.decodeIfPresent(Bool.self, forKey: .vision) ?? false
        enable = try container.decodeIfPresent(Bool.self, forKey: .enable) ?? false
        deprecated = try container.decodeIfPresent(Bool.self, forKey: .deprecated) ?? false
    }

    var openAIModel: OpenAIModel {
        OpenAIModel(id: modelId)
    }
}
