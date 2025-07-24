import XCTest
import RxSwift
@testable import chatGPT

final class StubOpenAIRepository: OpenAIRepository {
    var result: Single<Bool> = .just(false)
    private(set) var receivedPrompt: String?

    func detectImageIntent(prompt: String) -> Single<Bool> {
        receivedPrompt = prompt
        return result
    }

    func fetchAvailableModels(completion: @escaping (Result<[OpenAIModel], Error>) -> Void) {}
    func sendChat(messages: [Message], model: OpenAIModel, stream: Bool, completion: @escaping (Result<String, Error>) -> Void) {}
    func sendChatStream(messages: [Message], model: OpenAIModel) -> Observable<String> { .empty() }
    func sendVision(messages: [VisionMessage], model: OpenAIModel, stream: Bool, completion: @escaping (Result<String, Error>) -> Void) {}
    func sendVisionStream(messages: [VisionMessage], model: OpenAIModel) -> Observable<String> { .empty() }
    func generateImage(prompt: String, size: String, model: String, completion: @escaping (Result<[String], Error>) -> Void) {}
    func generateImageVariation(image: Data, size: String, model: String, completion: @escaping (Result<[String], Error>) -> Void) {}
    func generateImageEdit(image: Data, mask: Data?, prompt: String, size: String, model: String, completion: @escaping (Result<[String], Error>) -> Void) {}
}

final class DetectImageRequestUseCaseTests: XCTestCase {
    private var useCase: DetectImageRequestUseCase!
    private var repository: StubOpenAIRepository!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        repository = StubOpenAIRepository()
        useCase = DetectImageRequestUseCase(repository: repository)
        disposeBag = DisposeBag()
    }

    func test_positive_detection() {
        let prompt = "이미지 만들어줘"
        repository.result = .just(true)
        let exp = expectation(description: "positive")
        var output = false
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { value in
                output = value
                exp.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertTrue(output)
        XCTAssertEqual(repository.receivedPrompt, prompt)
    }

    func test_negative_sentence() {
        let prompt = "이미지는 만들지마"
        repository.result = .just(false)
        let exp = expectation(description: "negative")
        var output = true
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { value in
                output = value
                exp.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertFalse(output)
        XCTAssertEqual(repository.receivedPrompt, prompt)
    }

    func test_detection_in_english() {
        let prompt = "please generate an image"
        repository.result = .just(true)
        let exp = expectation(description: "english")
        var output = false
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { value in
                output = value
                exp.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertTrue(output)
        XCTAssertEqual(repository.receivedPrompt, prompt)
    }

    func test_detection_in_other_language() {
        let prompt = "por favor no hagas una imagen"
        repository.result = .just(false)
        let exp = expectation(description: "spanish")
        var output = true
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { value in
                output = value
                exp.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertFalse(output)
        XCTAssertEqual(repository.receivedPrompt, prompt)
    }

    func test_detection_returnsFalse_onError() {
        enum TestError: Error { case sample }
        repository.result = .error(TestError.sample)
        let exp = expectation(description: "error")
        var output = true
        useCase.execute(prompt: "error")
            .subscribe(onSuccess: { value in
                output = value
                exp.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertFalse(output)
    }
}
