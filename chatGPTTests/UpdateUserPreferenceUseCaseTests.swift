import XCTest
import RxSwift
@testable import chatGPT

final class StubPreferenceRepository: UserPreferenceRepository {
    private(set) var updatedUid: String?
    private(set) var updatedItems: [PreferenceItem] = []

    func fetch(uid: String) -> Single<UserPreference?> { .just(nil) }

    func update(uid: String, items: [PreferenceItem]) -> Single<Void> {
        updatedUid = uid
        updatedItems = items
        return .just(())
    }
}

final class StubEventRepository: PreferenceEventRepository {
    private(set) var events: [PreferenceEvent] = []
    func add(uid: String, events: [PreferenceEvent]) -> Single<Void> {
        self.events = events
        return .just(())
    }
    func fetch(uid: String) -> Single<[PreferenceEvent]> { .just([]) }
}

final class StubAuthRepository: AuthRepository {
    var user: AuthUser? = AuthUser(uid: "u1", displayName: nil, photoURL: nil)
    func observeAuthState() -> Observable<AuthUser?> { .empty() }
    func currentUser() -> AuthUser? { user }
    func signOut() throws {}
}

final class StubTranslationRepository: TranslationRepository {
    var mapping: [String: String] = [:]
    func translateToEnglish(_ text: String) -> Single<String> {
        .just(mapping[text] ?? text)
    }
}

final class UpdateUserPreferenceUseCaseTests: XCTestCase {
    private var useCase: UpdateUserPreferenceUseCase!
    private var repo: StubPreferenceRepository!
    private var eventRepo: StubEventRepository!
    private var translator: StubTranslationRepository!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        repo = StubPreferenceRepository()
        eventRepo = StubEventRepository()
        translator = StubTranslationRepository()
        let authRepo = StubAuthRepository()
        let getUser = GetCurrentUserUseCase(repository: authRepo)
        useCase = UpdateUserPreferenceUseCase(repository: repo,
                                             eventRepository: eventRepo,
                                             getCurrentUserUseCase: getUser,
                                             translationRepository: translator)
        disposeBag = DisposeBag()
    }

    func test_like_sentence() {
        let prompt = "I like apples"
        let exp = expectation(description: "like")
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { _ in exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        let item = repo.updatedItems.first
        XCTAssertEqual(item?.key, "apples")
        XCTAssertEqual(item?.relation, .like)
        XCTAssertEqual(item?.count, 1)
        XCTAssertEqual(eventRepo.events.first?.key, "apples")
    }

    func test_avoid_sentence() {
        let prompt = "avoid beer"
        let exp = expectation(description: "avoid")
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { _ in exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        let item = repo.updatedItems.first
        XCTAssertEqual(item?.key, "beer")
        XCTAssertEqual(item?.relation, .avoid)
        XCTAssertEqual(item?.count, 1)
    }

    func test_want_sentence() {
        let prompt = "I want coke"
        let exp = expectation(description: "want")
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { _ in exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        let item = repo.updatedItems.first
        XCTAssertEqual(item?.key, "coke")
        XCTAssertEqual(item?.relation, .want)
        XCTAssertEqual(item?.count, 1)
    }

    func test_multiple_preferences_count() {
        let prompt = "I like icons and I like icons"
        let exp = expectation(description: "multiple")
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { _ in exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertEqual(repo.updatedItems.count, 2)
        XCTAssertEqual(repo.updatedItems.first?.count, 1)
        XCTAssertEqual(repo.updatedItems.last?.count, 1)
    }

    func test_translation() {
        translator.mapping["リンゴが好きです"] = "I like apples"
        let prompt = "リンゴが好きです"
        let exp = expectation(description: "translate")
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { _ in exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        let item = repo.updatedItems.first
        XCTAssertEqual(item?.key, "apples")
        XCTAssertEqual(item?.relation, .like)
    }

    func test_parse_multiple_relations_in_sentence() {
        let prompt = "I like apples but dislike bananas"
        let exp = expectation(description: "multi")
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { _ in exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertEqual(repo.updatedItems.count, 2)
        XCTAssertEqual(repo.updatedItems[0].relation, .like)
        XCTAssertEqual(repo.updatedItems[0].key, "apples")
        XCTAssertEqual(repo.updatedItems[1].relation, .dislike)
        XCTAssertEqual(repo.updatedItems[1].key, "bananas")
    }

    func test_parse_korean_sentence() {
        translator.mapping["사과 좋아하고 맥주 피하고 싶어"] = "like apple avoid beer"
        let prompt = "사과 좋아하고 맥주 피하고 싶어"
        let exp = expectation(description: "korean")
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { _ in exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertEqual(repo.updatedItems.count, 2)
        XCTAssertEqual(repo.updatedItems[0].relation, .like)
        XCTAssertEqual(repo.updatedItems[0].key, "apple")
        XCTAssertEqual(repo.updatedItems[1].relation, .avoid)
        XCTAssertEqual(repo.updatedItems[1].key, "beer")
    }

    func test_parse_with_punctuation_and_case() {
        let prompt = "LIKE Pizza, AVOID Broccoli!"
        let exp = expectation(description: "punctuation")
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { _ in exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertEqual(repo.updatedItems.count, 2)
        XCTAssertEqual(repo.updatedItems[0].key, "pizza")
        XCTAssertEqual(repo.updatedItems[0].relation, .like)
        XCTAssertEqual(repo.updatedItems[1].key, "broccoli")
        XCTAssertEqual(repo.updatedItems[1].relation, .avoid)
    }
}
