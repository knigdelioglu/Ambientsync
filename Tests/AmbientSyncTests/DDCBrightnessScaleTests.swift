import XCTest
@testable import AmbientSync

final class DDCBrightnessScaleTests: XCTestCase {
    func testRawTargetClampsAndRounds() {
        XCTAssertEqual(DDCBrightnessScale.rawTarget(forUIPercent: -10, rawMax: 1000), 0)
        XCTAssertEqual(DDCBrightnessScale.rawTarget(forUIPercent: 50, rawMax: 1000), 500)
        XCTAssertEqual(DDCBrightnessScale.rawTarget(forUIPercent: 101, rawMax: 1000), 1000)
    }

    func testUIPercentRoundsAndClamps() {
        XCTAssertEqual(DDCBrightnessScale.uiPercent(fromRawCurrent: -10, rawMax: 1000), 0)
        XCTAssertEqual(DDCBrightnessScale.uiPercent(fromRawCurrent: 500, rawMax: 1000), 50)
        XCTAssertEqual(DDCBrightnessScale.uiPercent(fromRawCurrent: 1200, rawMax: 1000), 100)
    }

    func testMatchedUsesTolerance() {
        XCTAssertTrue(DDCBrightnessScale.isMatched(rawAfter: 100, computedRawTarget: 101, tolerance: 2))
        XCTAssertFalse(DDCBrightnessScale.isMatched(rawAfter: 100, computedRawTarget: 104, tolerance: 2))
    }
}
