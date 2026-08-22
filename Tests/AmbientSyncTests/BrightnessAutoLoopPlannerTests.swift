import XCTest
@testable import AmbientSync

final class BrightnessAutoLoopPlannerTests: XCTestCase {
    func testPreflightReturnsCalibrationSuppression() {
        let planner = BrightnessAutoLoopPlanner()
        let context = BrightnessAutoLoopPreflightContext(
            ambientLux: 55,
            target: 60,
            smoothedRequested: 61,
            currentActual: 50,
            now: Date(),
            lastWriteDate: .distantPast,
            minInterval: 1,
            updateThreshold: 3,
            currentDisplayKey: "display",
            calibrationActive: true,
            appBrightnessSuppressedUntil: .distantPast,
            ddcAvailable: true,
            brightnessLimiterCooldownDisplayKey: nil,
            brightnessLimiterCooldownUntil: .distantPast
        )

        let decision = planner.preflight(context: context)

        switch decision {
        case .suppressed(let reason, _, _, _, _):
            let typedReason: BrightnessSuppressionReason = reason
            XCTAssertEqual(typedReason, .autoDisabled)
        case .proceed:
            XCTFail("Expected suppression")
        }
    }

    func testPreflightReturnsDebounceSuppression() {
        let planner = BrightnessAutoLoopPlanner()
        let now = Date()
        let context = BrightnessAutoLoopPreflightContext(
            ambientLux: 55,
            target: 60,
            smoothedRequested: 61,
            currentActual: 50,
            now: now,
            lastWriteDate: now.addingTimeInterval(-0.2),
            minInterval: 1,
            updateThreshold: 3,
            currentDisplayKey: "display",
            calibrationActive: false,
            appBrightnessSuppressedUntil: .distantPast,
            ddcAvailable: true,
            brightnessLimiterCooldownDisplayKey: nil,
            brightnessLimiterCooldownUntil: .distantPast
        )

        let decision = planner.preflight(context: context)

        switch decision {
        case .suppressed(let reason, _, _, _, _):
            let typedReason: BrightnessSuppressionReason = reason
            XCTAssertEqual(typedReason, .debounceWaiting)
        case .proceed:
            XCTFail("Expected suppression")
        }
    }

    func testPreflightUsesProfileUpdateThresholdForTargetEquality() {
        let planner = BrightnessAutoLoopPlanner()
        let context = BrightnessAutoLoopPreflightContext(
            ambientLux: 55,
            target: 52,
            smoothedRequested: 51,
            currentActual: 50,
            now: Date(),
            lastWriteDate: .distantPast,
            minInterval: 1,
            updateThreshold: 4,
            currentDisplayKey: "display",
            calibrationActive: false,
            appBrightnessSuppressedUntil: .distantPast,
            ddcAvailable: true,
            brightnessLimiterCooldownDisplayKey: nil,
            brightnessLimiterCooldownUntil: .distantPast
        )

        let decision = planner.preflight(context: context)

        switch decision {
        case .suppressed(let reason, _, _, _, _):
            XCTAssertEqual(reason, .targetEqualsActual)
        case .proceed:
            XCTFail("Expected suppression")
        }
    }

    func testPreflightPromotesTinySmoothedStepToTarget() {
        let planner = BrightnessAutoLoopPlanner()
        let context = BrightnessAutoLoopPreflightContext(
            ambientLux: 220,
            target: 55,
            smoothedRequested: 51,
            currentActual: 50,
            now: Date(),
            lastWriteDate: .distantPast,
            minInterval: 1,
            updateThreshold: 3,
            currentDisplayKey: "display",
            calibrationActive: false,
            appBrightnessSuppressedUntil: .distantPast,
            ddcAvailable: true,
            brightnessLimiterCooldownDisplayKey: nil,
            brightnessLimiterCooldownUntil: .distantPast
        )

        let decision = planner.preflight(context: context)

        switch decision {
        case .proceed(let candidate, _):
            XCTAssertEqual(candidate, 55)
        case .suppressed:
            XCTFail("Expected write")
        }
    }
}
