import Combine
import CoreGraphics
import Foundation

@MainActor
final class DisplayConnectionController: ObservableObject {
    static let shared = DisplayConnectionController()

    @Published private(set) var snapshot: DisplayConnectionSnapshot = .initial
    @Published private(set) var isBusy = false

    private let backend: DisplayConnectionBackend
    private let identity: DisplayConnectionIdentity

    init(
        backend: DisplayConnectionBackend = PrivateDisplayConnectionBackend(),
        identity: DisplayConnectionIdentity = .samsungS60UD
    ) {
        self.backend = backend
        self.identity = identity
    }

    @discardableResult
    func refresh() -> DisplayConnectionSnapshot {
        guard backend.isAvailable else {
            return publish(
                phase: .unsupported,
                displayID: nil,
                isOnline: false,
                isActive: false,
                canToggle: false,
                message: "Yazılımsal ekran ayırma bu macOS sürümünde kullanılamıyor."
            )
        }

        do {
            let allIDs = try backend.allDisplayIDs()
            guard let displayID = resolveTargetDisplayID(from: allIDs) else {
                return publish(
                    phase: .physicallyDisconnected,
                    displayID: nil,
                    isOnline: false,
                    isActive: false,
                    canToggle: false,
                    message: "Samsung S60UD fiziksel olarak bağlı görünmüyor."
                )
            }

            let isOnline = CGDisplayIsOnline(displayID) != 0
            let isActive = CGDisplayIsActive(displayID) != 0
            let phase = DisplayConnectionPolicy.phase(
                targetFoundInPrivateList: true,
                isOnline: isOnline,
                isActive: isActive
            )

            let message: String
            switch phase {
            case .connected:
                message = "Samsung S60UD bağlı."
            case .softwareDisconnected:
                message = "Samsung S60UD yazılımsal olarak ayrıldı."
            default:
                message = "Samsung S60UD bağlantı durumu güncellendi."
            }

            return publish(
                phase: phase,
                displayID: displayID,
                isOnline: isOnline,
                isActive: isActive,
                canToggle: phase == .connected || phase == .softwareDisconnected,
                message: message
            )
        } catch {
            return publishFailure(error)
        }
    }

    @discardableResult
    func toggle() -> DisplayConnectionSnapshot {
        let current = refresh()
        switch current.phase {
        case .connected:
            return disconnect()
        case .softwareDisconnected:
            return reconnect()
        default:
            return current
        }
    }

    @discardableResult
    func disconnect() -> DisplayConnectionSnapshot {
        guard !isBusy else { return snapshot }
        isBusy = true
        defer { isBusy = false }

        let current = refresh()
        guard current.phase == .connected, let displayID = current.displayID else {
            return current
        }

        let activeIDs = activeDisplayIDs()
        guard DisplayConnectionPolicy.canDisable(
            targetDisplayID: displayID,
            activeDisplayIDs: activeIDs
        ) else {
            return publish(
                phase: .failed,
                displayID: displayID,
                isOnline: current.isOnline,
                isActive: current.isActive,
                canToggle: true,
                message: "Son aktif ekran kapatılamaz. Başka bir ekran aktif olmalı."
            )
        }

        _ = publish(
            phase: .disconnecting,
            displayID: displayID,
            isOnline: true,
            isActive: true,
            canToggle: false,
            message: "Samsung S60UD ayrılıyor…"
        )

        do {
            try backend.setDisplayEnabled(false, displayID: displayID)
            return refresh()
        } catch {
            return publishFailure(error, displayID: displayID)
        }
    }

    @discardableResult
    func reconnect() -> DisplayConnectionSnapshot {
        guard !isBusy else { return snapshot }
        isBusy = true
        defer { isBusy = false }

        guard backend.isAvailable else { return refresh() }

        do {
            let allIDs = try backend.allDisplayIDs()
            guard let displayID = resolveTargetDisplayID(from: allIDs) else {
                return publish(
                    phase: .physicallyDisconnected,
                    displayID: nil,
                    isOnline: false,
                    isActive: false,
                    canToggle: false,
                    message: "Samsung S60UD private ekran listesinde bulunamadı."
                )
            }

            _ = publish(
                phase: .reconnecting,
                displayID: displayID,
                isOnline: CGDisplayIsOnline(displayID) != 0,
                isActive: CGDisplayIsActive(displayID) != 0,
                canToggle: false,
                message: "Samsung S60UD yeniden bağlanıyor…"
            )

            try backend.setDisplayEnabled(true, displayID: displayID)
            Thread.sleep(forTimeInterval: 0.25)
            return refresh()
        } catch {
            return publishFailure(error)
        }
    }

    private func resolveTargetDisplayID(from ids: [CGDirectDisplayID]) -> CGDirectDisplayID? {
        ids.first { displayID in
            guard CGDisplayIsBuiltin(displayID) == 0 else { return false }
            return CGDisplayVendorNumber(displayID) == identity.vendorID &&
                CGDisplayModelNumber(displayID) == identity.productID &&
                CGDisplaySerialNumber(displayID) == identity.serialNumber
        }
    }

    private func activeDisplayIDs() -> [CGDirectDisplayID] {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else { return [] }

        var ids = Array(repeating: CGDirectDisplayID(0), count: Int(count))
        let result = ids.withUnsafeMutableBufferPointer { buffer in
            CGGetActiveDisplayList(count, buffer.baseAddress, &count)
        }
        guard result == .success else { return [] }
        return Array(ids.prefix(Int(count)))
    }

    @discardableResult
    private func publish(
        phase: DisplayConnectionPhase,
        displayID: CGDirectDisplayID?,
        isOnline: Bool,
        isActive: Bool,
        canToggle: Bool,
        message: String
    ) -> DisplayConnectionSnapshot {
        let next = DisplayConnectionSnapshot(
            phase: phase,
            displayID: displayID,
            name: identity.name,
            isOnline: isOnline,
            isActive: isActive,
            canToggle: canToggle,
            message: message
        )
        snapshot = next
        return next
    }

    private func publishFailure(
        _ error: Error,
        displayID: CGDirectDisplayID? = nil
    ) -> DisplayConnectionSnapshot {
        publish(
            phase: .failed,
            displayID: displayID,
            isOnline: false,
            isActive: false,
            canToggle: true,
            message: error.localizedDescription
        )
    }
}
