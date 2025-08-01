import Foundation

struct UserProfile: Codable, Equatable {
    var attributes: [String: String] = [:]

    init(attributes: [String: String] = [:]) {
        self.attributes = attributes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        var attrs: [String: String] = [:]
        for key in container.allKeys {
            if let value = try? container.decode(String.self, forKey: key) {
                attrs[key.stringValue] = value
            } else if let intValue = try? container.decode(Int.self, forKey: key) {
                attrs[key.stringValue] = "\(intValue)"
            } else if let doubleValue = try? container.decode(Double.self, forKey: key) {
                attrs[key.stringValue] = "\(doubleValue)"
            }
        }
        self.attributes = attrs
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicKey.self)
        for (key, value) in attributes {
            try container.encode(value, forKey: DynamicKey(stringValue: key)!)
        }
    }

    struct DynamicKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int?
        init?(intValue: Int) { return nil }
    }
}
