import Foundation
import XCTest
@testable import AmbientSync

final class EDIDParserTests: XCTestCase {
    func testEmptyDataProducesUnavailableSummary() {
        let result = EDIDParser.parse(Data())

        XCTAssertEqual(result.status, .unavailable)
        XCTAssertTrue(result.notes.contains("EDID data unavailable"))
        XCTAssertEqual(result.info.rawByteCount, 0)
    }

    func testShortDataProducesPartialSummary() {
        let result = EDIDParser.parse(Data(repeating: 0x00, count: 32))

        XCTAssertEqual(result.status, .partial)
        XCTAssertTrue(result.notes.contains("EDID shorter than 128 bytes"))
    }
}
