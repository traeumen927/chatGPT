import XCTest
@testable import chatGPT

final class PreferenceAnalysisResultTests: XCTestCase {
    func test_decoding() throws {
        let json = #"{"info":{"occupation":"iOS developer","likes":["swift"]}}"#
        let data = Data(json.utf8)
        let result = try JSONDecoder().decode(PreferenceAnalysisResult.self, from: data)
        XCTAssertEqual(result.info.attributes["occupation"]?.first?.value, "iOS developer")
        XCTAssertEqual(result.info.attributes["likes"]?.first?.value, "swift")
    }
}
