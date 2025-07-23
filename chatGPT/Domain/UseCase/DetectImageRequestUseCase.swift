import Foundation

final class DetectImageRequestUseCase {
    private let keywords: [String]

    init(keywords: [String] = ["이미지", "그림", "사진", "image", "picture"]) {
        self.keywords = keywords
    }

    func execute(prompt: String) -> Bool {
        let lowerPrompt = prompt.lowercased()
        return keywords.contains { lowerPrompt.contains($0.lowercased()) }
    }
}
