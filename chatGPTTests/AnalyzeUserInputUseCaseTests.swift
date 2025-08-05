import XCTest
import RxSwift
@testable import chatGPT

final class StubInfoRepository: UserInfoRepository {
    private(set) var updated: [String: [UserFact]] = [:]
    func fetch(uid: String) -> Single<UserInfo?> { .just(nil) }
    func observe(uid: String) -> Observable<UserInfo?> { .empty() }
    func update(uid: String, attributes: [String : [UserFact]]) -> Single<Void> {
        updated = attributes
        return .just(())
    }
}

final class StubOpenAIRepository: OpenAIRepository {
    var analysisResult: PreferenceAnalysisResult = .init(info: UserInfo(attributes: [:]))
    func fetchAvailableModels(completion: @escaping (Result<[OpenAIModel], Error>) -> Void) {}
    func sendChat(messages: [Message], model: OpenAIModel, stream: Bool, completion: @escaping (Result<String, Error>) -> Void) {}
    func sendChatStream(messages: [Message], model: OpenAIModel) -> Observable<String> { .empty() }
    func sendVision(messages: [VisionMessage], model: OpenAIModel, stream: Bool, completion: @escaping (Result<String, Error>) -> Void) {}
    func sendVisionStream(messages: [VisionMessage], model: OpenAIModel) -> Observable<String> { .empty() }
    func generateImage(prompt: String, size: String, model: String, completion: @escaping (Result<[String], Error>) -> Void) {}
    func detectImageIntent(prompt: String) -> Single<Bool> { .just(false) }
    func analyzeUserInput(prompt: String) -> Single<PreferenceAnalysisResult> { .just(analysisResult) }
}

final class StubAuthRepository: AuthRepository {
    var user: AuthUser? = AuthUser(uid: "u1", displayName: nil, photoURL: nil)
    func observeAuthState() -> Observable<AuthUser?> { .empty() }
    func currentUser() -> AuthUser? { user }
    func signOut() throws {}
}

final class AnalyzeUserInputUseCaseTests: XCTestCase {
    private var useCase: AnalyzeUserInputUseCase!
    private var infoRepo: StubInfoRepository!
    private var openAI: StubOpenAIRepository!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        infoRepo = StubInfoRepository()
        openAI = StubOpenAIRepository()
        let auth = StubAuthRepository()
        let getUser = GetCurrentUserUseCase(repository: auth)
        useCase = AnalyzeUserInputUseCase(openAIRepository: openAI,
                                          infoRepository: infoRepo,
                                          getCurrentUserUseCase: getUser)
        disposeBag = DisposeBag()
    }

    func test_updates_info() {
        openAI.analysisResult = PreferenceAnalysisResult(
            info: UserInfo(attributes: [
                "drink": [UserFact(value: "coffee", count: 1, firstMentioned: 0, lastMentioned: 0)]
            ])
        )
        let exp = expectation(description: "update")
        useCase.execute(prompt: "I like coffee")
            .subscribe(onSuccess: { exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertEqual(infoRepo.updated["drink"]?.first?.value, "coffee")
    }
}
