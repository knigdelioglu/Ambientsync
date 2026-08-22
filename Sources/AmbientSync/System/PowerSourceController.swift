import AppKit
import Foundation
import IOKit
import IOKit.hid
import IOKit.ps
import IOKit.pwr_mgt
import Darwin
import SwiftUI

enum PowerSourceState {
    case ac
    case battery
    case unknown
}

final class PowerSourceController {
    func currentState() -> PowerSourceState {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let powerType = IOPSGetProvidingPowerSourceType(snapshot).takeRetainedValue()
        if powerType == kIOPMACPowerKey as CFString {
            return .ac
        }
        if powerType == kIOPMBatteryPowerKey as CFString {
            return .battery
        }
        return .unknown
    }
}
