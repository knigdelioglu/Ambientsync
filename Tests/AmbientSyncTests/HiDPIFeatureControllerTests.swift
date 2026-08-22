import XCTest
@testable import AmbientSync

final class HiDPIFeatureControllerTests: XCTestCase {
    func testIsHiDPIActiveDetectsScaledModes() {
        let fingerprint = CGSActiveModeFingerprint(
            modeID: 74,
            logicalWidth: 2560,
            logicalHeight: 1440,
            pixelWidth: 5120,
            pixelHeight: 2880,
            refreshRateHz: 100
        )

        XCTAssertTrue(HiDPIFeatureController.isHiDPIActive(activeFingerprint: fingerprint))
    }

    func testIsHiDPIActiveReturnsFalseForNativeResolution() {
        let fingerprint = CGSActiveModeFingerprint(
            modeID: 56,
            logicalWidth: 2560,
            logicalHeight: 1440,
            pixelWidth: 2560,
            pixelHeight: 1440,
            refreshRateHz: 100
        )

        XCTAssertFalse(HiDPIFeatureController.isHiDPIActive(activeFingerprint: fingerprint))
    }
}
