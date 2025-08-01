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
        repository.update(uid: "u1", attributes: ["age": "20"])
            .subscribe(onSuccess: { exp.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
        let call = firestore.lastBatch?.setCalls.first
        XCTAssertEqual(call?.document.path, "userInfo/u1")
        XCTAssertEqual(call?.data["age"] as? String, "20")
    }
}
