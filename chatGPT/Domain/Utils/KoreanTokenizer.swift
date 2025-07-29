import Foundation
import NaturalLanguage

struct KoreanTokenizer {
    private let tagger = NLTagger(tagSchemes: [.lexicalClass])

    func nouns(from text: String) -> [String] {
        tagger.string = text
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther]
        var tokens: [String] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, range in
            guard let tag = tag else { return true }
            if tag == .noun {
                var token = String(text[range])
                token = KoreanTokenizer.stripParticle(token)
                if !token.isEmpty {
                    tokens.append(token)
                }
            }
            return true
        }
        return tokens
    }

    private static func stripParticle(_ word: String) -> String {
        let particles = [
            "은", "는", "이", "가", "을", "를", "에", "에서", "에게", "한테",
            "도", "으로", "로", "과", "와", "부터", "까지", "마저", "조차", "뿐", "만",
            "처럼", "보다", "께서"
        ]
        for particle in particles {
            if word.hasSuffix(particle) {
                return String(word.dropLast(particle.count))
            }
        }
        return word
    }
}
