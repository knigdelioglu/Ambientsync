import AppKit
import CoreGraphics
import Foundation

public struct DisplayTarget: Sendable {
    public let displayID: CGDirectDisplayID
    public let name: String
}

enum DisplayTargetResolver {
    enum ResolverError: LocalizedError {
        case noExternalDisplays
        case noSamsungDisplay
        case multipleSamsungDisplays([String])

        var errorDescription: String? {
            switch self {
            case .noExternalDisplays:
                return "Harici ekran bulunamadı."
            case .noSamsungDisplay:
                return "Samsung S60UD / LS32D60 hedef ekranı bulunamadı."
            case .multipleSamsungDisplays(let names):
                return "Birden fazla Samsung hedef ekran bulundu; otomatik seçim yapılmadı: \(names.joined(separator: ", "))"
            }
        }
    }

    static func resolveActiveDisplay() throws -> DisplayTarget {
        if let displayID = NSScreen.main?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            let directDisplayID = displayID.uint32Value
            return DisplayTarget(displayID: directDisplayID, name: displayName(for: directDisplayID))
        }

        let mainDisplayID = CGMainDisplayID()
        guard mainDisplayID != 0 else { throw ResolverError.noExternalDisplays }
        return DisplayTarget(displayID: mainDisplayID, name: displayName(for: mainDisplayID))
    }

    static func resolveSamsungS60UD() throws -> DisplayTarget {
        let displays = onlineExternalDisplays()
        guard !displays.isEmpty else { throw ResolverError.noExternalDisplays }

        let priorityMatchers: [(DisplayTarget) -> Bool] = [
            { $0.name.localizedCaseInsensitiveContains("S60UD") },
            { $0.name.localizedCaseInsensitiveContains("LS32D60") },
            { $0.name.localizedCaseInsensitiveContains("Samsung") },
        ]

        for matches in priorityMatchers.map({ matcher in displays.filter(matcher) }) where !matches.isEmpty {
            guard matches.count == 1 else {
                throw ResolverError.multipleSamsungDisplays(matches.map(\.name))
            }
            return matches[0]
        }

        throw ResolverError.noSamsungDisplay
    }

    static func onlineExternalDisplays() -> [DisplayTarget] {
        var displayCount: UInt32 = 0
        guard CGGetOnlineDisplayList(0, nil, &displayCount) == .success, displayCount > 0 else {
            return []
        }

        var displays = Array(repeating: CGDirectDisplayID(0), count: Int(displayCount))
        guard CGGetOnlineDisplayList(displayCount, &displays, &displayCount) == .success else {
            return []
        }

        return displays.prefix(Int(displayCount)).compactMap { displayID in
            guard CGDisplayIsBuiltin(displayID) == 0 else { return nil }
            return DisplayTarget(displayID: displayID, name: displayName(for: displayID))
        }
    }

    static func displayName(for displayID: CGDirectDisplayID) -> String {
        for screen in NSScreen.screens {
            let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            if number?.uint32Value == displayID {
                return screen.localizedName
            }
        }
        return "Display \(displayID)"
    }
}
