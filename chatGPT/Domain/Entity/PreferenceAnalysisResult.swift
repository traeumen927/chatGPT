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
        let infoContainer = try container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .info)
        var attributes: [String: [UserFact]] = [:]
        let now = Date().timeIntervalSince1970
        for key in infoContainer.allKeys {
            if var arr = try? infoContainer.nestedUnkeyedContainer(forKey: key) {
                var facts: [UserFact] = []
                while !arr.isAtEnd {
                    if let str = try? arr.decode(String.self) {
                        facts.append(UserFact(value: str, count: 1, firstMentioned: now, lastMentioned: now))
                    } else if let intVal = try? arr.decode(Int.self) {
                        facts.append(UserFact(value: "\(intVal)", count: 1, firstMentioned: now, lastMentioned: now))
                    } else if let dblVal = try? arr.decode(Double.self) {
                        facts.append(UserFact(value: "\(dblVal)", count: 1, firstMentioned: now, lastMentioned: now))
                    } else if let boolVal = try? arr.decode(Bool.self) {
                        facts.append(UserFact(value: "\(boolVal)", count: 1, firstMentioned: now, lastMentioned: now))
                    } else {
                        _ = try? arr.decode(String.self)
                    }
                }
                attributes[key.stringValue] = facts
            } else if let str = try? infoContainer.decode(String.self, forKey: key) {
                attributes[key.stringValue] = [UserFact(value: str, count: 1, firstMentioned: now, lastMentioned: now)]
            } else if let intVal = try? infoContainer.decode(Int.self, forKey: key) {
                attributes[key.stringValue] = [UserFact(value: "\(intVal)", count: 1, firstMentioned: now, lastMentioned: now)]
            } else if let dblVal = try? infoContainer.decode(Double.self, forKey: key) {
                attributes[key.stringValue] = [UserFact(value: "\(dblVal)", count: 1, firstMentioned: now, lastMentioned: now)]
            } else if let boolVal = try? infoContainer.decode(Bool.self, forKey: key) {
                attributes[key.stringValue] = [UserFact(value: "\(boolVal)", count: 1, firstMentioned: now, lastMentioned: now)]
            }
        }
        self.info = UserInfo(attributes: attributes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var infoContainer = container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .info)
        for (key, facts) in info.attributes {
            let codingKey = DynamicCodingKey(stringValue: key)
            if facts.count == 1 {
                try infoContainer.encode(facts[0].value, forKey: codingKey)
            } else {
                var arr = infoContainer.nestedUnkeyedContainer(forKey: codingKey)
                for fact in facts { try arr.encode(fact.value) }
            }
        }
    }
}

private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    init(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int? { nil }
    init?(intValue: Int) { return nil }
}
