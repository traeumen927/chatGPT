import Foundation

struct MorphToken {
    let text: String
    let isNoun: Bool
}

struct MorphTokenizer {
    private static let postpositions: [String] = [
        "은", "는", "이", "가", "을", "를", "에", "에서", "에게", "한테", "와", "과",
        "랑", "으로", "로", "도", "만", "까지", "부터", "처럼", "뿐", "조차", "마저", "보다",
        "께", "께서"
    ]
    private static let verbEndings: [String] = [
        "다", "고", "하고", "해", "해요", "하는", "하다", "했다", "한다",
        "싶어", "싶다", "싶어라", "하", "되", "됐다", "시", "어"
    ]

    static func tokenize(_ text: String) -> [MorphToken] {
        let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        var tokens: [MorphToken] = []
        for raw in text.components(separatedBy: separators) where !raw.isEmpty {
            var word = raw.trimmingCharacters(in: .punctuationCharacters)
            var removed = true
            while removed {
                removed = false
                for pos in postpositions {
                    if word.hasSuffix(pos) {
                        word = String(word.dropLast(pos.count))
                        removed = true
                    }
                }
            }
            let lower = word.lowercased()
            let isHangul = lower.unicodeScalars.allSatisfy { $0.value >= 0xAC00 && $0.value <= 0xD7A3 }
            var isNoun = true
            if isHangul {
                for end in verbEndings {
                    if lower.hasSuffix(end) {
                        isNoun = false
                        break
                    }
                }
            }
            tokens.append(MorphToken(text: lower, isNoun: isNoun))
        }
        return tokens
    }
}
