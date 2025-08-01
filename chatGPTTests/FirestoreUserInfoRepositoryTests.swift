import XCTest
import RxSwift
@testable import chatGPT

final class FirestoreUserInfoRepositoryTests: XCTestCase {
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
    }

    func test_update_writes_data() {
        let firestore = Firestore()
        let repository = FirestoreUserInfoRepository(db: firestore)
        let exp = expectation(description: "update")
        let fact = UserFact(value: "20", count: 1, firstMentioned: 0, lastMentioned: 0)
        repository.update(uid: "u1", attributes: ["age": [fact]])
            .subscribe(onSuccess: { exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        let call = firestore.lastBatch?.setCalls.first
        XCTAssertEqual(call?.document.path, "profiles/u1/facts/age-20")
        XCTAssertEqual(call?.data["name"] as? String, "age")
        XCTAssertEqual(call?.data["value"] as? String, "20")
    }
}
