import XCTest
import RxSwift
@testable import chatGPT

final class UserContextBuilderTests: XCTestCase {
    func test_selects_attributes_in_prompt_and_top_by_count() {
        let now = Date().timeIntervalSince1970
        let store = UserMemoryStore()
        let info = UserInfo(attributes: [
            "age": [UserFact(value: "33", count: 5, firstMentioned: now - 1000, lastMentioned: now - 500)],
            "color": [UserFact(value: "blue", count: 2, firstMentioned: now - 1000, lastMentioned: now - 500)],
            "hobby": [UserFact(value: "chess", count: 3, firstMentioned: now - 1000, lastMentioned: now - 500)]
        ])
        store.bind(.just(info))
        let builder = UserContextBuilder(store: store, maxAttributes: 2)
        let profile = builder.buildProfile(for: "tell me your hobby")
        XCTAssertEqual(profile, "age: 33, hobby: chess")
    }

    func test_falls_back_to_top_attributes_when_prompt_has_no_match() {
        let now = Date().timeIntervalSince1970
        let store = UserMemoryStore()
        let info = UserInfo(attributes: [
            "color": [UserFact(value: "blue", count: 5, firstMentioned: now - 1000, lastMentioned: now - 500)],
            "food": [UserFact(value: "sushi", count: 2, firstMentioned: now - 1000, lastMentioned: now - 500)]
        ])
        store.bind(.just(info))
        let builder = UserContextBuilder(store: store, maxAttributes: 1)
        let profile = builder.buildProfile(for: "hello")
        XCTAssertEqual(profile, "color: blue")
    }
}
