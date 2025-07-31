import Foundation

struct MorphToken {
    let text: String
    let isNoun: Bool
}

struct MorphTokenizer {
    static func tokenize(_ text: String) -> [MorphToken] {
        let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        return text
            .components(separatedBy: separators)
            .filter { !$0.isEmpty }
            .map { MorphToken(text: $0.lowercased(), isNoun: true) }
    }
}
