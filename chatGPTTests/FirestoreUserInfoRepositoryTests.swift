import XCTest
import RxSwift
@testable import chatGPT

final class FirestoreUserInfoRepositoryTests: XCTestCase {
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
    }

    func test_update_increments_count_and_preserves_firstMentioned() {
        let firestore = Firestore()
        let repository = FirestoreUserInfoRepository(db: firestore)

        let exp1 = expectation(description: "first")
        let first = UserFact(value: "udon", count: 1, firstMentioned: 100, lastMentioned: 100)
        repository.update(uid: "u1", attributes: ["likes": [first]])
            .subscribe(onSuccess: { exp1.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)

        let exp2 = expectation(description: "second")
        let second = UserFact(value: "udon", count: 1, firstMentioned: 200, lastMentioned: 200)
        repository.update(uid: "u1", attributes: ["likes": [second]])
            .subscribe(onSuccess: { exp2.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)

        let doc = firestore.documents["profiles/u1/facts/likes-udon"]
        XCTAssertEqual(doc?["count"] as? Int, 2)
        XCTAssertEqual(doc?["firstMentioned"] as? TimeInterval, 100)
        XCTAssertEqual(doc?["lastMentioned"] as? TimeInterval, 200)
    }
}
