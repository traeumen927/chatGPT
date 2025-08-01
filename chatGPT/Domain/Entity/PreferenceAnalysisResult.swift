import Foundation

struct PreferenceAnalysisResult: Codable {
    let info: UserInfo

    enum CodingKeys: String, CodingKey {
        case info
    }

    init(info: UserInfo) {
        self.info = info
    }

    enum JSONValue: Codable {
        case string(String)
        case number(Double)
        case bool(Bool)
        case array([JSONValue])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let str = try? container.decode(String.self) {
                self = .string(str)
                return
            }
            if let num = try? container.decode(Double.self) {
                self = .number(num)
                return
            }
            if let bool = try? container.decode(Bool.self) {
                self = .bool(bool)
                return
            }
            if let arr = try? container.decode([JSONValue].self) {
                self = .array(arr)
                return
            }
            self = .string("")
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let str):
                try container.encode(str)
            case .number(let num):
                try container.encode(num)
            case .bool(let bool):
                try container.encode(bool)
            case .array(let arr):
                try container.encode(arr)
            }
        }

        var stringValue: String {
            switch self {
            case .string(let str):
                return str
            case .number(let num):
                let intVal = Int(num)
                return Double(intVal) == num ? String(intVal) : String(num)
            case .bool(let bool):
                return bool ? "true" : "false"
            case .array(let arr):
                return arr.map { $0.stringValue }.joined(separator: ",")
            }
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let values = try container.decode([String: JSONValue].self, forKey: .info)
        let attributes = values.mapValues { $0.stringValue }
        self.info = UserInfo(attributes: attributes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(info.attributes, forKey: .info)
    }
}
