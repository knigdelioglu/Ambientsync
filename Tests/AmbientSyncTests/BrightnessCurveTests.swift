import XCTest
@testable import AmbientSync

final class BrightnessCurveTests: XCTestCase {
    func testAmbientNormalizedValueIsClampedAndMonotonic() {
        let calibration = DisplayCalibration(lowLux: 20, midLux: 350, highLux: 650)

        let dark = BrightnessCurve.ambientNormalizedValue(for: 0, calibration: calibration)
        let low = BrightnessCurve.ambientNormalizedValue(for: 20, calibration: calibration)
        let mid = BrightnessCurve.ambientNormalizedValue(for: 350, calibration: calibration)
        let bright = BrightnessCurve.ambientNormalizedValue(for: 900, calibration: calibration)

        XCTAssertEqual(dark, 0, accuracy: 0.0001)
        XCTAssertLessThan(low, mid)
        XCTAssertLessThan(mid, bright)
        XCTAssertLessThanOrEqual(bright, 100)
        XCTAssertGreaterThanOrEqual(bright, 0)
    }

    func testAutoTargetBrightnessIncreasesWithLux() {
        let calibration = DisplayCalibration(lowLux: 20, midLux: 350, highLux: 650)
        let profile = AmbientSyncProfile.defaultProfiles[2]

        let darkTarget = BrightnessCurve.targetBrightness(for: 10, calibration: calibration, profile: profile)
        let roomTarget = BrightnessCurve.targetBrightness(for: 350, calibration: calibration, profile: profile)
        let brightTarget = BrightnessCurve.targetBrightness(for: 900, calibration: calibration, profile: profile)

        XCTAssertLessThanOrEqual(darkTarget, roomTarget)
        XCTAssertLessThan(roomTarget, brightTarget)
        XCTAssertLessThanOrEqual(brightTarget, 100)
        XCTAssertGreaterThanOrEqual(darkTarget, 0)
    }

    func testDefaultBalancedCurveDoesNotFlattenMidRoomLux() {
        let calibration = DisplayCalibration(lowLux: 20, midLux: 350, highLux: 650)
        let profile = AmbientSyncProfile.defaultProfiles[2]

        let lowerRoomTarget = BrightnessCurve.targetBrightness(for: 250, calibration: calibration, profile: profile)
        let brighterRoomTarget = BrightnessCurve.targetBrightness(for: 430, calibration: calibration, profile: profile)

        XCTAssertEqual(lowerRoomTarget, 37)
        XCTAssertEqual(brighterRoomTarget, 50)
        XCTAssertGreaterThanOrEqual(brighterRoomTarget - lowerRoomTarget, 10)
    }

    func testNormalizedAutoTargetMapsProfileAnchorsDirectly() {
        let calibration = DisplayCalibration(lowLux: 20, midLux: 350, highLux: 650)
        let profile = AmbientSyncProfile.defaultProfiles[2]

        XCTAssertEqual(BrightnessCurve.autoTargetBrightnessPercent(for: 25, calibration: calibration, profile: profile), profile.lowBrightness)
        XCTAssertEqual(BrightnessCurve.autoTargetBrightnessPercent(for: 50, calibration: calibration, profile: profile), profile.midBrightness)
        XCTAssertEqual(BrightnessCurve.autoTargetBrightnessPercent(for: 75, calibration: calibration, profile: profile), profile.highBrightness)
    }
}
