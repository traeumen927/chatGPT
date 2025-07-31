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
    func delete(uid: String, eventID: String) -> Single<Void> { .just(()) }
}

final class StubStatusRepository: PreferenceStatusRepository {
    private(set) var statuses: [PreferenceStatus] = []
    func fetch(uid: String) -> Single<[PreferenceStatus]> { .just(statuses) }
    func update(uid: String, status: PreferenceStatus) -> Single<Void> {
        if let index = statuses.firstIndex(where: { $0.key == status.key }) {
            statuses[index] = status
        } else {
            statuses.append(status)
        }
        return .just(())
    }
    func delete(uid: String, key: String) -> Single<Void> { .just(()) }
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
    private var statusRepo: StubStatusRepository!
    private var translator: StubTranslationRepository!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        repo = StubPreferenceRepository()
        eventRepo = StubEventRepository()
        statusRepo = StubStatusRepository()
        translator = StubTranslationRepository()
        let authRepo = StubAuthRepository()
        let getUser = GetCurrentUserUseCase(repository: authRepo)
        useCase = UpdateUserPreferenceUseCase(repository: repo,
                                             eventRepository: eventRepo,
                                             statusRepository: statusRepo,
                                             getCurrentUserUseCase: getUser,
                                             translationRepository: translator)
        disposeBag = DisposeBag()
    }

    func test_like_sentence() {
        let prompt = "사과를 좋아해"
        let exp = expectation(description: "like")
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { _ in exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertTrue(repo.updatedItems.isEmpty)
        XCTAssertTrue(eventRepo.events.isEmpty)
    }

    func test_avoid_sentence() {
        let prompt = "맥주 피하고 싶어"
        let exp = expectation(description: "avoid")
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { _ in exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertTrue(repo.updatedItems.isEmpty)
    }

    func test_want_sentence() {
        let prompt = "콜라 마시고 싶어"
        let exp = expectation(description: "want")
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { _ in exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertTrue(repo.updatedItems.isEmpty)
    }

    func test_multiple_preferences_count() {
        let prompt = "아이콘 좋아하고 아이콘 좋아해"
        let exp = expectation(description: "multiple")
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { _ in exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertTrue(repo.updatedItems.isEmpty)
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
        let prompt = "사과 좋아하지만 바나나는 싫어"
        let exp = expectation(description: "multi")
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { _ in exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertTrue(repo.updatedItems.isEmpty)
    }

    func test_parse_korean_sentence() {
        let prompt = "사과 좋아하고 맥주 피하고 싶어"
        let exp = expectation(description: "korean")
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { _ in exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertTrue(repo.updatedItems.isEmpty)
    }

    func test_parse_with_punctuation_and_case() {
        let prompt = "사과 좋아!, 브로콜리 피하고 싶어!"
        let exp = expectation(description: "punctuation")
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { _ in exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertTrue(repo.updatedItems.isEmpty)
    }
}
