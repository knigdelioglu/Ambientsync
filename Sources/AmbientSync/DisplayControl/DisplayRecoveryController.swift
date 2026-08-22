import AppKit
import CoreGraphics
import Foundation

final class DisplayRecoveryController: @unchecked Sendable {
    private let onDisplaysChanged: @Sendable () -> Void
    private var observers: [NSObjectProtocol] = []
    private var callbackRegistered = false

    init(onDisplaysChanged: @escaping @Sendable () -> Void) {
        self.onDisplaysChanged = onDisplaysChanged
    }

    func start() {
        guard !callbackRegistered else { return }
        callbackRegistered = CGDisplayRegisterReconfigurationCallback(Self.displayCallback, unmanagedSelf) == .success

        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.onDisplaysChanged()
        })
        observers.append(center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.onDisplaysChanged()
        })
    }

    func stop() {
        if callbackRegistered {
            CGDisplayRemoveReconfigurationCallback(Self.displayCallback, unmanagedSelf)
            callbackRegistered = false
        }

        let center = NSWorkspace.shared.notificationCenter
        for observer in observers {
            center.removeObserver(observer)
        }
        observers.removeAll()
    }

    private var unmanagedSelf: UnsafeMutableRawPointer {
        Unmanaged.passUnretained(self).toOpaque()
    }

    private static let displayCallback: CGDisplayReconfigurationCallBack = { _, _, userInfo in
        guard let userInfo else { return }
        let controller = Unmanaged<DisplayRecoveryController>.fromOpaque(userInfo).takeUnretainedValue()
        controller.onDisplaysChanged()
    }
}
