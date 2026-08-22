import AppKit
import CoreGraphics
import Darwin
import Foundation

private typealias ExternalDisplayServicesGetBrightnessFn = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
private typealias ExternalDisplayServicesSetBrightnessFn = @convention(c) (CGDirectDisplayID, Float) -> Int32
private typealias ExternalDisplayServicesCanChangeBrightnessFn = @convention(c) (CGDirectDisplayID) -> Bool
private typealias ExternalDisplayServicesBrightnessChangedFn = @convention(c) (CGDirectDisplayID, Double) -> Void
private typealias ExternalCoreDisplayGetUserBrightnessFn = @convention(c) (CGDirectDisplayID) -> Double
private typealias ExternalCoreDisplaySetUserBrightnessFn = @convention(c) (CGDirectDisplayID, Double) -> Void

final class ExternalDisplayBrightnessController: @unchecked Sendable {
    private let displayServicesGetBrightness: ExternalDisplayServicesGetBrightnessFn?
    private let displayServicesSetBrightness: ExternalDisplayServicesSetBrightnessFn?
    private let displayServicesCanChangeBrightness: ExternalDisplayServicesCanChangeBrightnessFn?
    private let displayServicesBrightnessChanged: ExternalDisplayServicesBrightnessChangedFn?
    private let coreDisplayGetUserBrightness: ExternalCoreDisplayGetUserBrightnessFn?
    private let coreDisplaySetUserBrightness: ExternalCoreDisplaySetUserBrightnessFn?

    init() {
        let displayServicesHandle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY)
        let coreDisplayHandle = dlopen("/System/Library/Frameworks/CoreDisplay.framework/CoreDisplay", RTLD_LAZY)

        displayServicesGetBrightness = Self.symbol("DisplayServicesGetBrightness", from: displayServicesHandle)
        displayServicesSetBrightness = Self.symbol("DisplayServicesSetBrightness", from: displayServicesHandle)
        displayServicesCanChangeBrightness = Self.symbol("DisplayServicesCanChangeBrightness", from: displayServicesHandle)
        displayServicesBrightnessChanged = Self.symbol("DisplayServicesBrightnessChanged", from: displayServicesHandle)
        coreDisplayGetUserBrightness = Self.symbol("CoreDisplay_Display_GetUserBrightness", from: coreDisplayHandle)
        coreDisplaySetUserBrightness = Self.symbol("CoreDisplay_Display_SetUserBrightness", from: coreDisplayHandle)
    }

    func currentBrightness(for display: ExternalDisplayInfo) -> Int? {
        guard let displayID = resolveDisplayID(for: display) else { return nil }

        if let displayServicesGetBrightness {
            var value: Float = 0
            if displayServicesGetBrightness(displayID, &value) == 0 {
                return Self.percent(from: value)
            }
        }

        if let coreDisplayGetUserBrightness {
            return Self.percent(from: Float(coreDisplayGetUserBrightness(displayID)))
        }

        return nil
    }

    func setBrightness(_ percent: Int, for display: ExternalDisplayInfo) -> Bool {
        guard let displayID = resolveDisplayID(for: display) else { return false }

        if let displayServicesCanChangeBrightness, !displayServicesCanChangeBrightness(displayID) {
            return false
        }

        let value = Float(min(100, max(0, percent))) / 100.0
        if let displayServicesSetBrightness, displayServicesSetBrightness(displayID, value) == 0 {
            if let displayServicesBrightnessChanged {
                displayServicesBrightnessChanged(displayID, Double(value))
            }
            return true
        }

        if let coreDisplaySetUserBrightness {
            coreDisplaySetUserBrightness(displayID, Double(value))
            if let displayServicesBrightnessChanged {
                displayServicesBrightnessChanged(displayID, Double(value))
            }
            return true
        }

        return false
    }

    private func resolveDisplayID(for display: ExternalDisplayInfo) -> CGDirectDisplayID? {
        if let displayID = display.displayID, Self.isOnlineExternalDisplay(displayID) {
            return displayID
        }

        let online = Self.onlineExternalDisplays()
        if online.count == 1 {
            return online[0]
        }

        return nil
    }

    private static func onlineExternalDisplays() -> [CGDirectDisplayID] {
        var displayCount: UInt32 = 0
        guard CGGetOnlineDisplayList(0, nil, &displayCount) == .success, displayCount > 0 else {
            return []
        }

        var displays = Array(repeating: CGDirectDisplayID(0), count: Int(displayCount))
        guard CGGetOnlineDisplayList(displayCount, &displays, &displayCount) == .success else {
            return []
        }

        return displays.prefix(Int(displayCount)).filter { isOnlineExternalDisplay($0) }
    }

    private static func isOnlineExternalDisplay(_ displayID: CGDirectDisplayID) -> Bool {
        CGDisplayIsOnline(displayID) != 0 && CGDisplayIsBuiltin(displayID) == 0
    }

    private static func percent(from brightness: Float) -> Int? {
        guard brightness.isFinite else { return nil }
        let scaled = Int((brightness * 100).rounded())
        return min(100, max(0, scaled))
    }

    private static func symbol<T>(_ name: String, from handle: UnsafeMutableRawPointer?) -> T? {
        guard let handle, let raw = dlsym(handle, name) else { return nil }
        return unsafeBitCast(raw, to: T.self)
    }
}
