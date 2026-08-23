import XCTest
@testable import AmbientSync

final class KeepAwakeFeatureControllerTests: XCTestCase {
    func testStartDurationModeActivatesTemporaryOverride() {
        let controller = KeepAwakeFeatureController()
        var state = KeepAwakeState(
            featureEnabled: true,
            defaultIdleTimeoutMode: "15",
            defaultIdleTimeoutMinutes: 15,
            temporaryIdleTimeoutMode: nil,
            temporaryIdleTimeoutMinutes: nil,
            temporaryOverrideActive: false,
            onlyWhilePluggedIn: false,
            keepDisplayAwake: true,
            idleSleepAssertionID: 0,
            displaySleepAssertionID: 0,
            lastWakeTriggerAt: nil,
            lastStopReason: "none"
        )

        controller.startDurationMode("30", state: &state)

        XCTAssertTrue(state.temporaryOverrideActive)
        XCTAssertEqual(state.temporaryIdleTimeoutMode, "30")
        XCTAssertNil(state.temporaryIdleTimeoutMinutes)
    }

    func testStartCustomMinutesActivatesCustomTemporaryOverride() {
        let controller = KeepAwakeFeatureController()
        var state = KeepAwakeState(
            featureEnabled: true,
            defaultIdleTimeoutMode: "15",
            defaultIdleTimeoutMinutes: 15,
            temporaryIdleTimeoutMode: nil,
            temporaryIdleTimeoutMinutes: nil,
            temporaryOverrideActive: false,
            onlyWhilePluggedIn: false,
            keepDisplayAwake: true,
            idleSleepAssertionID: 0,
            displaySleepAssertionID: 0,
            lastWakeTriggerAt: nil,
            lastStopReason: "none"
        )

        controller.startCustomMinutes(95, state: &state)

        XCTAssertTrue(state.temporaryOverrideActive)
        XCTAssertEqual(state.temporaryIdleTimeoutMode, "custom")
        XCTAssertEqual(state.temporaryIdleTimeoutMinutes, 95)
    }

    func testStartDefaultSessionClearsTemporaryOverride() {
        let controller = KeepAwakeFeatureController()
        var state = KeepAwakeState(
            featureEnabled: true,
            defaultIdleTimeoutMode: "15",
            defaultIdleTimeoutMinutes: 15,
            temporaryIdleTimeoutMode: "30",
            temporaryIdleTimeoutMinutes: 45,
            temporaryOverrideActive: true,
            onlyWhilePluggedIn: false,
            keepDisplayAwake: true,
            idleSleepAssertionID: 0,
            displaySleepAssertionID: 0,
            lastWakeTriggerAt: nil,
            lastStopReason: "none"
        )

        controller.startDefaultSession(state: &state)

        XCTAssertFalse(state.temporaryOverrideActive)
        XCTAssertNil(state.temporaryIdleTimeoutMode)
        XCTAssertNil(state.temporaryIdleTimeoutMinutes)
    }
}
