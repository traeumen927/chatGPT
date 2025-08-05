import Foundation

final class UserContextBuilder {
    private let store: UserMemoryStore
    private let maxAttributes: Int

    init(store: UserMemoryStore = .shared, maxAttributes: Int = 3) {
        self.store = store
        self.maxAttributes = maxAttributes
    }

    func buildProfile(for prompt: String) -> String? {
        guard let info = store.info else { return nil }
        let lower = prompt.lowercased()
        var selected: [String: [UserFact]] = [:]
        // pick attributes mentioned in the prompt
        for (key, facts) in info.attributes {
            if lower.contains(key.lowercased()) {
                selected[key] = facts
            }
        }
        // fill remaining slots with most frequent attributes
        if selected.count < maxAttributes {
            let sorted = info.attributes
                .sorted { lhs, rhs in
                    let l = lhs.value.map { $0.count }.reduce(0, +)
                    let r = rhs.value.map { $0.count }.reduce(0, +)
                    return l > r
                }
            for (key, facts) in sorted where selected[key] == nil && selected.count < maxAttributes {
                selected[key] = facts
            }
        }
        guard !selected.isEmpty else { return nil }
        let parts = selected
            .sorted { $0.key < $1.key }
            .map { key, facts in
                let values = facts.map { $0.value }.joined(separator: ", ")
                return "\(key): \(values)"
            }
        return parts.joined(separator: ", ")
    }
}
