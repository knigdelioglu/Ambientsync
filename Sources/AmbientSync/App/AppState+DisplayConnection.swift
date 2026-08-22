import Foundation

extension AppState {
    var displayConnectionController: DisplayConnectionController {
        .shared
    }

    func refreshDisplayConnectionState() {
        _ = displayConnectionController.refresh()
    }

    func toggleExternalDisplayConnection() {
        let result = displayConnectionController.toggle()
        statusText = result.message

        // Reuse the existing DDC/HiDPI rediscovery pipeline after either direction.
        // On disconnect it clears stale DDC state; on reconnect it rediscovers the
        // monitor and lets the existing HiDPI refresh/reapply flow recover normally.
        refreshDisplay()
    }
}
