import XCTest
@testable import AmbientSync

final class VolumeFeatureControllerTests: XCTestCase {
    func testMenuTitlesReflectCurrentVolume() {
        let controller = VolumeFeatureController()
        let titles = controller.menuTitles(currentVolume: 42, lastNonZeroVolume: 17)

        XCTAssertEqual(titles.soundTitle, "Ses: %42")
        XCTAssertEqual(titles.volumeStatusTitle, "Ses: %42")
        XCTAssertEqual(titles.topVolumeStatusTitle, "Ses: %42")
        XCTAssertEqual(titles.muteItemTitle, "Sessiz")
    }

    func testMenuTitlesUseOpenLabelWhenMuted() {
        let controller = VolumeFeatureController()
        let titles = controller.menuTitles(currentVolume: 0, lastNonZeroVolume: 17)

        XCTAssertEqual(titles.muteItemTitle, "Sesi aç")
    }
}
