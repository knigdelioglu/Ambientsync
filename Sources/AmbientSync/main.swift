import AppKit
import Foundation
import IOKit
import IOKit.hid
import IOKit.ps
import IOKit.pwr_mgt
import Darwin
import SwiftUI

if CommandLine.arguments.contains("--release-bundle-smoke") {
    do {
        let record = try HiDPIOverrideReferenceStore.bundledReferenceRecord()
        guard record.vendorID == HiDPIOverrideReferenceStore.targetVendorID,
              record.productID == HiDPIOverrideReferenceStore.targetProductID,
              record.perfectQHDRecordsPresent else {
            fputs("Release bundle resource validation failed\n", stderr)
            exit(1)
        }
        print("Release bundle smoke check passed")
        exit(0)
    } catch {
        fputs("Release bundle smoke check failed: \(error.localizedDescription)\n", stderr)
        exit(1)
    }
}

if CommandLine.arguments.contains("--diagnostic") {
    HiDPIDiagnostic.run()
    exit(0)
}

if CommandLine.arguments.contains("--hidpi-mode-pool-diagnostic") {
    HiDPIDiagnostic.runModePoolDiagnostic()
    exit(0)
}

if CommandLine.arguments.contains("--cgs-mode-enumeration") {
    do {
        let summary = try CGSModeEnumerationDiagnostic.runEnumeration()
        print("CGS mode enumeration report written: \(summary.reportURL.path)")
        print("CGS current mode id: \(summary.currentModeID.map(String.init) ?? "unavailable")")
        print("CGS mode count: \(summary.cgsModeCount)")
        print("Public duplicate count: \(summary.publicDuplicateModeCount)")
    } catch {
        fputs("CGS mode enumeration failed: \(error.localizedDescription)\n", stderr)
        exit(1)
    }
    exit(0)
}

if CommandLine.arguments.contains("--cgs-mode74-without-betterdisplay") {
    do {
        let summary = try CGSModeEnumerationDiagnostic.runWithoutBetterDisplayVerification()
        print("CGS mode 74 check report written: \(summary.reportURL.path)")
        print("CGS current mode id: \(summary.currentModeID.map(String.init) ?? "unavailable")")
        print("CGS mode count: \(summary.cgsModeCount)")
        print("Public duplicate count: \(summary.publicDuplicateModeCount)")
        print("Mode 74 present: \(summary.mode74 != nil)")
        print("Mode 74 perfect QHD: \(summary.mode74IsPerfectQHD)")
    } catch {
        fputs("CGS mode 74 check failed: \(error.localizedDescription)\n", stderr)
        exit(1)
    }
    exit(0)
}

if CommandLine.arguments.contains("--cgs-mode74-apply-experiment") {
    do {
        let summary = try CGSModeEnumerationDiagnostic.runMode56Then74ApplyExperiment()
        print("CGS apply experiment report written: \(summary.reportURL.path)")
        print("Before mode id: \(summary.initialModeID.map(String.init) ?? "unavailable")")
        print("Mode 56 verified: \(summary.mode56Verified)")
        print("Mode 74 verified: \(summary.mode74Verified)")
        print("Final active mode: \(summary.finalSummary.activeModeDescription)")
        print("Success: \(summary.success)")
    } catch {
        fputs("CGS apply experiment failed: \(error.localizedDescription)\n", stderr)
        exit(1)
    }
    exit(0)
}

if let snapshotIndex = CommandLine.arguments.firstIndex(of: "--hidpi-system-snapshot") {
    guard CommandLine.arguments.indices.contains(snapshotIndex + 1) else {
        fputs("Missing output directory after --hidpi-system-snapshot\n", stderr)
        exit(2)
    }

    do {
        let outputURL = URL(fileURLWithPath: CommandLine.arguments[snapshotIndex + 1])
        try HiDPISystemSnapshotReporter.writeSnapshot(to: outputURL)
        print("HiDPI system snapshot written: \(outputURL.path)")
    } catch {
        fputs("HiDPI system snapshot failed: \(error.localizedDescription)\n", stderr)
        exit(1)
    }
    exit(0)
}

if CommandLine.arguments.contains("--hidpi-activation-spike") {
    let result = await HiDPIActivationEngine.runExperimentalSpike()
    print("HiDPI activation spike report written: \(result.reportURL.path)")
    print("Classification: \(result.classification)")
    print("Perfect QHD appeared: \(result.perfectQHDAppeared)")
    print("Applied Perfect QHD: \(result.appliedPerfectQHD)")
    exit(0)
}

let app = NSApplication.shared
let delegate = AppState()
app.delegate = delegate
app.run()
