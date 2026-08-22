import XCTest
@testable import AmbientSync

final class HiDPIReapplyDecisionTests: XCTestCase {
    func testShouldReapplyWhenActiveModeDiffers() {
        let controller = HiDPIFeatureController()
        let active = CGSActiveModeFingerprint(
            modeID: 56,
            logicalWidth: 2560,
            logicalHeight: 1440,
            pixelWidth: 2560,
            pixelHeight: 1440,
            refreshRateHz: 100
        )
        let selected = CGSDisplayModeCandidate(
            modeID: 74,
            ioMode: 1,
            logicalWidth: 2560,
            logicalHeight: 1440,
            pixelWidth: 5120,
            pixelHeight: 2880,
            refreshRate: 100,
            flags: 0,
            ioFlags: 0,
            isHiDPI: true,
            isLowRes: false,
            scaleFactor: 2,
            aspectRatio: 16.0 / 9.0,
            score: 10,
            reason: "selected"
        )

        let decision = controller.shouldReapplyHiDPI(activeFingerprint: active, selectedCandidate: selected)

        XCTAssertTrue(decision.shouldApply)
    }

    func testShouldNotReapplyWhenAlreadyOnSelectedMode() {
        let controller = HiDPIFeatureController()
        let active = CGSActiveModeFingerprint(
            modeID: 74,
            logicalWidth: 2560,
            logicalHeight: 1440,
            pixelWidth: 5120,
            pixelHeight: 2880,
            refreshRateHz: 100
        )
        let selected = CGSDisplayModeCandidate(
            modeID: 74,
            ioMode: 1,
            logicalWidth: 2560,
            logicalHeight: 1440,
            pixelWidth: 5120,
            pixelHeight: 2880,
            refreshRate: 100,
            flags: 0,
            ioFlags: 0,
            isHiDPI: true,
            isLowRes: false,
            scaleFactor: 2,
            aspectRatio: 16.0 / 9.0,
            score: 10,
            reason: "selected"
        )

        let decision = controller.shouldReapplyHiDPI(activeFingerprint: active, selectedCandidate: selected)

        XCTAssertFalse(decision.shouldApply)
        XCTAssertEqual(decision.reason, "Ekran zaten seçili HiDPI modunda.")
    }
}
