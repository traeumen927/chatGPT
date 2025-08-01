import XCTest
@testable import chatGPT

final class PreferenceAnalysisResultTests: XCTestCase {
    func test_decoding() throws {
        let json = #"{"info":{"occupation":"iOS developer"}}"#
        let data = Data(json.utf8)
        let result = try JSONDecoder().decode(PreferenceAnalysisResult.self, from: data)
        XCTAssertEqual(result.info.attributes["occupation"], "iOS developer")
    }

    func test_decoding_array_value() throws {
        let json = #"{"info":{"hobby":["soccer","movie"]}}"#
        let data = Data(json.utf8)
        let result = try JSONDecoder().decode(PreferenceAnalysisResult.self, from: data)
        XCTAssertEqual(result.info.attributes["hobby"], "soccer,movie")
    }

    func test_decoding_number_value() throws {
        let json = #"{"info":{"age":25}}"#
        let data = Data(json.utf8)
        let result = try JSONDecoder().decode(PreferenceAnalysisResult.self, from: data)
        XCTAssertEqual(result.info.attributes["age"], "25")
    }
}
