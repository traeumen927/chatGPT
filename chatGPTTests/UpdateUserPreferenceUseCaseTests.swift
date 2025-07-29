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

final class UpdateUserPreferenceUseCaseTests: XCTestCase {
    private var useCase: UpdateUserPreferenceUseCase!
    private var repo: StubPreferenceRepository!
    private var eventRepo: StubEventRepository!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        repo = StubPreferenceRepository()
        eventRepo = StubEventRepository()
        let authRepo = StubAuthRepository()
        let getUser = GetCurrentUserUseCase(repository: authRepo)
        useCase = UpdateUserPreferenceUseCase(repository: repo, eventRepository: eventRepo, getCurrentUserUseCase: getUser)
        disposeBag = DisposeBag()
    }

    func test_like_sentence() {
        let prompt = "나는 사과를 좋아해"
        let exp = expectation(description: "like")
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { _ in exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        let item = repo.updatedItems.first
        XCTAssertEqual(item?.key, "사과")
        XCTAssertEqual(item?.relation, .like)
        XCTAssertEqual(item?.count, 1)
        XCTAssertEqual(eventRepo.events.first?.key, "사과")
    }

    func test_avoid_sentence_with_particle() {
        let prompt = "술은 하지마"
        let exp = expectation(description: "avoid")
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { _ in exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        let item = repo.updatedItems.first
        XCTAssertEqual(item?.key, "술")
        XCTAssertEqual(item?.relation, .avoid)
        XCTAssertEqual(item?.count, 1)
    }

    func test_want_sentence() {
        let prompt = "콜라 원해"
        let exp = expectation(description: "want")
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { _ in exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        let item = repo.updatedItems.first
        XCTAssertEqual(item?.key, "콜라")
        XCTAssertEqual(item?.relation, .want)
        XCTAssertEqual(item?.count, 1)
    }

    func test_multiple_preferences_count() {
        let prompt = "아이콘 좋아하고 아이콘 좋아해"
        let exp = expectation(description: "multiple")
        useCase.execute(prompt: prompt)
            .subscribe(onSuccess: { _ in exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertEqual(repo.updatedItems.count, 2)
        XCTAssertEqual(repo.updatedItems.first?.count, 1)
        XCTAssertEqual(repo.updatedItems.last?.count, 1)
    }
}
