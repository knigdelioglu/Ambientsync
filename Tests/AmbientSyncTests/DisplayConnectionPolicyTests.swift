import CoreGraphics
import XCTest
@testable import AmbientSync

final class DisplayConnectionPolicyTests: XCTestCase {
    func testConnectedPhaseRequiresOnlineAndActive() {
        XCTAssertEqual(
            DisplayConnectionPolicy.phase(
                targetFoundInPrivateList: true,
                isOnline: true,
                isActive: true,
                softwareDisconnectRequested: false
            ),
            .connected
        )
    }

    func testPrivateButInactiveDisplayIsSoftwareDisconnectedWhenRequested() {
        XCTAssertEqual(
            DisplayConnectionPolicy.phase(
                targetFoundInPrivateList: true,
                isOnline: false,
                isActive: false,
                softwareDisconnectRequested: true
            ),
            .softwareDisconnected
        )
    }

    func testPrivateButInactiveDisplayIsPhysicalWhenNotRequested() {
        XCTAssertEqual(
            DisplayConnectionPolicy.phase(
                targetFoundInPrivateList: true,
                isOnline: false,
                isActive: false,
                softwareDisconnectRequested: false
            ),
            .physicallyDisconnected
        )
    }

    func testMissingPrivateDisplayIsPhysicallyDisconnected() {
        XCTAssertEqual(
            DisplayConnectionPolicy.phase(
                targetFoundInPrivateList: false,
                isOnline: false,
                isActive: false,
                softwareDisconnectRequested: true
            ),
            .physicallyDisconnected
        )
    }

    func testLastActiveDisplayCannotBeDisabled() {
        let target = CGDirectDisplayID(42)
        XCTAssertFalse(
            DisplayConnectionPolicy.canDisable(
                targetDisplayID: target,
                activeDisplayIDs: [target]
            )
        )
    }

    func testTargetCanBeDisabledWhenAnotherDisplayRemainsActive() {
        let target = CGDirectDisplayID(42)
        XCTAssertTrue(
            DisplayConnectionPolicy.canDisable(
                targetDisplayID: target,
                activeDisplayIDs: [CGDirectDisplayID(1), target]
            )
        )
    }
}
