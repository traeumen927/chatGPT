import XCTest
import RxSwift
@testable import chatGPT

final class StubEventRepository: PreferenceEventRepository {
    var events: [PreferenceEvent] = []
    func add(uid: String, events: [PreferenceEvent]) -> Single<Void> { .just(()) }
    func fetch(uid: String) -> Single<[PreferenceEvent]> { .just(events) }
    func delete(uid: String, eventID: String) -> Single<Void> { .just(()) }
}

final class StubAuthRepository: AuthRepository {
    var user: AuthUser? = AuthUser(uid: "u1", displayName: nil, photoURL: nil)
    func observeAuthState() -> Observable<AuthUser?> { .empty() }
    func currentUser() -> AuthUser? { user }
    func signOut() throws {}
}

final class CalculatePreferenceUseCaseTests: XCTestCase {
    private var useCase: CalculatePreferenceUseCase!
    private var repo: StubEventRepository!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        repo = StubEventRepository()
        let authRepo = StubAuthRepository()
        let getUser = GetCurrentUserUseCase(repository: authRepo)
        useCase = CalculatePreferenceUseCase(eventRepository: repo,
                                             getCurrentUserUseCase: getUser)
        disposeBag = DisposeBag()
    }

    func test_returns_sorted_by_decay_weight() {
        let now = Date().timeIntervalSince1970
        repo.events = [
            PreferenceEvent(key: "a", relation: PreferenceRelation(rawValue: "like"), timestamp: now - 1000),
            PreferenceEvent(key: "b", relation: PreferenceRelation(rawValue: "like"), timestamp: now - 10),
            PreferenceEvent(key: "a", relation: PreferenceRelation(rawValue: "like"), timestamp: now - 20)
        ]
        let exp = expectation(description: "sorted")
        var output: [PreferenceEvent] = []
        useCase.execute(top: 2)
            .subscribe(onSuccess: { events in
                output = events
                exp.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertEqual(output.count, 2)
        XCTAssertEqual(output[0].key, "a")
        XCTAssertEqual(output[1].key, "b")
    }

    func test_handles_large_time_difference() {
        let now = Date().timeIntervalSince1970
        repo.events = [
            PreferenceEvent(key: "old", relation: PreferenceRelation(rawValue: "like"), timestamp: now - 31_536_000),
            PreferenceEvent(key: "recent", relation: PreferenceRelation(rawValue: "like"), timestamp: now - 1)
        ]
        let exp = expectation(description: "decay")
        var output: [PreferenceEvent] = []
        useCase.execute(top: 2)
            .subscribe(onSuccess: { events in
                output = events
                exp.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        XCTAssertEqual(output.first?.key, "recent")
        XCTAssertEqual(output.last?.key, "old")
    }
}

