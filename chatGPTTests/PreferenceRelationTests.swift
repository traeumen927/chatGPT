import XCTest
@testable import chatGPT

final class PreferenceRelationTests: XCTestCase {
    func test_init_preserves_raw_value() {
        let r = PreferenceRelation(rawValue: "love")
        XCTAssertEqual(r.rawValue, "love")
    }

    func test_sanitized_removes_invalid_chars() {
        let r = PreferenceRelation(rawValue: "like/love too")
        XCTAssertEqual(r.sanitized, "like_love_too")
    }
}
