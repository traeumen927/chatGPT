import XCTest
import RxSwift
@testable import chatGPT

final class StubPreferenceRepository: UserPreferenceRepository {
    private(set) var updatedItems: [PreferenceItem] = []
    func fetch(uid: String) -> Single<UserPreference?> { .just(nil) }
    func update(uid: String, items: [PreferenceItem]) -> Single<Void> {
        updatedItems = items
        return .just(())
    }
}

final class StubProfileRepository: UserProfileRepository {
    private(set) var updated: UserProfile?
    func fetch(uid: String) -> Single<UserProfile?> { .just(nil) }
    func update(uid: String, profile: UserProfile) -> Single<Void> {
        updated = profile
        return .just(())
    }
}

final class StubOpenAIRepository: OpenAIRepository {
    var analysisResult: PreferenceAnalysisResult = .init(preferences: [], profile: nil)
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
    private var prefRepo: StubPreferenceRepository!
    private var profileRepo: StubProfileRepository!
    private var openAI: StubOpenAIRepository!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        prefRepo = StubPreferenceRepository()
        profileRepo = StubProfileRepository()
        openAI = StubOpenAIRepository()
        let auth = StubAuthRepository()
        let getUser = GetCurrentUserUseCase(repository: auth)
        useCase = AnalyzeUserInputUseCase(openAIRepository: openAI,
                                          preferenceRepository: prefRepo,
                                          profileRepository: profileRepo,
                                          getCurrentUserUseCase: getUser)
        disposeBag = DisposeBag()
    }

    func test_updates_preference_and_profile() {
        openAI.analysisResult = PreferenceAnalysisResult(
            preferences: [PreferenceAnalysisResult.Preference(key: "coffee", relation: PreferenceRelation(rawValue: "like"))],
            profile: UserProfile(attributes: ["age": "20", "gender": "male"])
        )
        let exp = expectation(description: "update")
        useCase.execute(prompt: "I like coffee")
            .subscribe(onSuccess: { exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertEqual(prefRepo.updatedItems.first?.key, "coffee")
        XCTAssertEqual(prefRepo.updatedItems.first?.relation, PreferenceRelation(rawValue: "like"))
        XCTAssertEqual(profileRepo.updated?.attributes["age"], "20")
    }
}
