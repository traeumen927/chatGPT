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

final class StubAuthRepository: AuthRepository {
    var user: AuthUser? = AuthUser(uid: "u1", displayName: nil, photoURL: nil)
    func observeAuthState() -> Observable<AuthUser?> { .empty() }
    func currentUser() -> AuthUser? { user }
    func signOut() throws {}
}

final class UpdateUserPreferenceUseCaseTests: XCTestCase {
    private var useCase: UpdateUserPreferenceUseCase!
    private var repo: StubPreferenceRepository!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        repo = StubPreferenceRepository()
        let authRepo = StubAuthRepository()
        let getUser = GetCurrentUserUseCase(repository: authRepo)
        useCase = UpdateUserPreferenceUseCase(repository: repo, getCurrentUserUseCase: getUser)
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
    }
}
