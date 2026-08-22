import XCTest
@testable import AmbientSync

final class HiDPIActivationCandidateSelectionTests: XCTestCase {
    func testChooseActivationCandidatePrefersDynamicHiDPI() {
        let controller = HiDPIFeatureController()
        let dynamic = CGSDisplayModeCandidate(
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
            reason: "dynamic"
        )

        let selection = controller.chooseActivationCandidate(
            enabled: true,
            dynamicHiDPI: dynamic,
            fallbackHiDPI: nil,
            dynamicNormal: nil,
            fallbackNormal: nil
        )

        XCTAssertEqual(selection.selectedCandidate?.modeID, dynamic.modeID)
        XCTAssertEqual(selection.updateMessage, "HiDPI enabled")
    }

    func testChooseActivationCandidateReportsFailureWhenMissing() {
        let controller = HiDPIFeatureController()

        let selection = controller.chooseActivationCandidate(
            enabled: true,
            dynamicHiDPI: nil,
            fallbackHiDPI: nil,
            dynamicNormal: nil,
            fallbackNormal: nil
        )

        XCTAssertNil(selection.selectedCandidate)
        XCTAssertEqual(selection.statusMessage, "Uygun HiDPI modu CGS mode listesinde bulunamadı.")
    }
}
