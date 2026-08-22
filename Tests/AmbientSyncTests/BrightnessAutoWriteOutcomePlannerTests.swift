import XCTest
@testable import AmbientSync

final class BrightnessAutoWriteOutcomePlannerTests: XCTestCase {
    func testPlanSuccessWithAcceptedButLimitedReadbackSetsCooldown() {
        let planner = BrightnessAutoWriteOutcomePlanner()
        let result = M1DDCBrightnessWriteResult(
            success: true,
            status: .writeAcceptedButReadbackLimited,
            message: "Limiter active",
            requestedUIPercent: 70,
            rawMax: 100,
            computedRawTarget: 70,
            rawBefore: 40,
            rawAfter: 40,
            actualUIPercentAfter: 40,
            readbackBrightnessPercent: 40,
            readbackAvailable: true,
            matchedTarget: false
        )

        let outcome = planner.plan(result: result, candidate: 70)

        XCTAssertTrue(outcome.shouldSetCooldown)
        XCTAssertEqual(outcome.statusText, "Limiter active")
    }

    func testPlanFailureProducesReadableStatus() {
        let planner = BrightnessAutoWriteOutcomePlanner()
        let result = M1DDCBrightnessWriteResult(
            success: false,
            status: .writeFailed,
            message: "m1ddc failed",
            requestedUIPercent: 70,
            rawMax: nil,
            computedRawTarget: nil,
            rawBefore: nil,
            rawAfter: nil,
            actualUIPercentAfter: nil,
            readbackBrightnessPercent: nil,
            readbackAvailable: false,
            matchedTarget: nil
        )

        let outcome = planner.planFailure(result: result, currentActual: 42)

        XCTAssertEqual(outcome.statusText, "Yazma hatası: m1ddc failed")
        XCTAssertEqual(outcome.actualAfter, 42)
        XCTAssertFalse(outcome.shouldSetCooldown)
    }
}
