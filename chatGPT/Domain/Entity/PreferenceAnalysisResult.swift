import Foundation

struct PreferenceAnalysisResult: Codable {
    let info: UserInfo

    enum CodingKeys: String, CodingKey {
        case info
    }

    init(info: UserInfo) {
        self.info = info
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let attributes = try container.decode([String: String].self, forKey: .info)
        self.info = UserInfo(attributes: attributes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(info.attributes, forKey: .info)
    }
}
