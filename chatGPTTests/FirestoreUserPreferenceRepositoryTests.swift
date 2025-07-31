import XCTest
import RxSwift
@testable import chatGPT

// MARK: - Tests
final class FirestoreUserPreferenceRepositoryTests: XCTestCase {
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
    }

    func test_update_writes_data() {
        let firestore = Firestore()
        let repository = FirestoreUserPreferenceRepository(db: firestore)
        let now = Date().timeIntervalSince1970
        let item = PreferenceItem(key: "apple", relation: PreferenceRelation(rawValue: "like"), updatedAt: now, count: 1)
        let exp = expectation(description: "update")
        repository.update(uid: "u1", items: [item])
            .subscribe(onSuccess: { exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        let call = firestore.lastBatch?.setCalls.first
        XCTAssertEqual(call?.document.path, "preferences/u1/items/apple_like")
        XCTAssertEqual(call?.data["key"] as? String, "apple")
        XCTAssertEqual(call?.data["relation"] as? String, "like")
        XCTAssertEqual(call?.data["updatedAt"] as? String, "SERVER_TIMESTAMP")
    }

    func test_update_handles_arbitrary_relation() {
        let firestore = Firestore()
        let repository = FirestoreUserPreferenceRepository(db: firestore)
        let now = Date().timeIntervalSince1970
        let item = PreferenceItem(key: "banana", relation: PreferenceRelation(rawValue: "love"), updatedAt: now, count: 1)
        let exp = expectation(description: "update")
        repository.update(uid: "u1", items: [item])
            .subscribe(onSuccess: { exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        let call = firestore.lastBatch?.setCalls.first
        XCTAssertEqual(call?.document.path, "preferences/u1/items/banana_love")
        XCTAssertEqual(call?.data["relation"] as? String, "love")
    }
}
