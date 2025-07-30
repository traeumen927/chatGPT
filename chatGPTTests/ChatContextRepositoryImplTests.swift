import XCTest
@testable import chatGPT

final class ChatContextRepositoryImplTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "test_\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func test_persist_messages_and_summary() {
        var repo: ChatContextRepositoryImpl? = ChatContextRepositoryImpl(userDefaults: defaults)
        repo?.append(role: .user, content: "hi")
        repo?.updateSummary("sum")
        repo = nil
        let loaded = ChatContextRepositoryImpl(userDefaults: defaults)
        XCTAssertEqual(loaded.messages.first?.content, "hi")
        XCTAssertEqual(loaded.summary, "sum")
    }
}
