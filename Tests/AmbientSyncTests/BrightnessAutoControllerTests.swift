import XCTest
@testable import AmbientSync

final class BrightnessAutoControllerTests: XCTestCase {
    func testSmoothedRequestedPercentMovesTowardTarget() {
        let controller = BrightnessAutoController()

        let result = controller.smoothedRequestedPercent(target: 80, reference: 50, smoothing: 0.2)

        XCTAssertEqual(result, 56)
    }

    func testSmoothedRequestedPercentNeverGetsStuckOnReference() {
        let controller = BrightnessAutoController()

        let result = controller.smoothedRequestedPercent(target: 51, reference: 50, smoothing: 0.01)

        XCTAssertEqual(result, 51)
    }

    func testManualOverrideContinuesWhileLuxChangeIsSmall() {
        let controller = BrightnessAutoController()
        let now = Date()

        let shouldHold = controller.shouldContinueManualOverride(
            currentLux: 52,
            startLux: 50,
            overrideUntil: now.addingTimeInterval(20),
            now: now
        )

        XCTAssertTrue(shouldHold)
    }

    func testManualOverrideStopsAfterLargeLuxChange() {
        let controller = BrightnessAutoController()
        let now = Date()

        let shouldHold = controller.shouldContinueManualOverride(
            currentLux: 180,
            startLux: 50,
            overrideUntil: now.addingTimeInterval(20),
            now: now
        )

        XCTAssertFalse(shouldHold)
    }
}
