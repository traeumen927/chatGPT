import XCTest

final class DetectImageRequestUseCase {
    private let keywords: [String]
    private let negativeIndicators: [String]

    init(keywords: [String] = ["이미지", "그림", "사진", "image", "picture"], negativeIndicators: [String] = ["하지마", "하지 마", "만들지마", "만들지 마", "그리지마", "그리지 마", "no", "don't", "dont", "not"]) {
        self.keywords = keywords
        self.negativeIndicators = negativeIndicators
    }

    func execute(prompt: String) -> Bool {
        let lowerPrompt = prompt.lowercased()
        if negativeIndicators.contains(where: { lowerPrompt.contains($0.lowercased()) }) {
            return false
        }
        return keywords.contains { lowerPrompt.contains($0.lowercased()) }
    }
}

final class DetectImageRequestUseCaseTests: XCTestCase {
    private var useCase: DetectImageRequestUseCase!

    override func setUp() {
        super.setUp()
        useCase = DetectImageRequestUseCase()
    }

    func test_positive_detection() {
        let prompt = "이미지 만들어줘"
        XCTAssertTrue(useCase.execute(prompt: prompt))
    }

    func test_negative_sentence() {
        let prompt = "이미지는 만들지마"
        XCTAssertFalse(useCase.execute(prompt: prompt))
    }

    func test_detection_in_english() {
        let prompt = "please generate an image"
        XCTAssertTrue(useCase.execute(prompt: prompt))
    }

    func test_detection_in_other_language() {
        let prompt = "por favor no hagas una imagen"
        XCTAssertFalse(useCase.execute(prompt: prompt))
    }
}
