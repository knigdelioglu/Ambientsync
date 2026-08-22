import AppKit
import Foundation
import IOKit
import IOKit.hid
import IOKit.ps
import IOKit.pwr_mgt
import Darwin
import SwiftUI

@MainActor
final class QuickActionsPopoverController: NSObject {
    private let popover: NSPopover
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?
    private let menuBarClearance: CGFloat = 12
    var onVisibilityChanged: ((Bool) -> Void)?

    init(app: AppState) {
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        let visibleHeight = NSScreen.main?.visibleFrame.height ?? 720
        // Size the popover to its final resting position up front so we do not
        // need to nudge the window after it appears.
        popover.contentSize = NSSize(
            width: 296,
            height: min(640, max(500, visibleHeight - 48 - menuBarClearance))
        )
        popover.contentViewController = NSHostingController(rootView: MenuBarLeftPanelView(app: app))
        super.init()
        popover.delegate = self
    }

    func toggle(relativeTo view: NSView) {
        if popover.isShown {
            popover.performClose(nil)
            removeMonitors()
            return
        }
        
        NSApp.activate(ignoringOtherApps: true)
        // NSStatusBarButton is standard coordinate system, minY is bottom edge.
        popover.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
        
        // Add monitors to close the popover when clicking outside
        setupMonitors()
    }
    
    private func setupMonitors() {
        removeMonitors()
        
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                if event.window != strongSelf.popover.contentViewController?.view.window {
                    strongSelf.popover.performClose(nil)
                    strongSelf.removeMonitors()
                }
            }
            return event
        }
        
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.popover.performClose(nil)
                strongSelf.removeMonitors()
            }
        }
    }
    
    private func removeMonitors() {
        if let local = localEventMonitor {
            NSEvent.removeMonitor(local)
            localEventMonitor = nil
        }
        if let global = globalEventMonitor {
            NSEvent.removeMonitor(global)
            globalEventMonitor = nil
        }
    }
}

extension QuickActionsPopoverController: NSPopoverDelegate {
    @objc func popoverWillShow(_ notification: Notification) {
        onVisibilityChanged?(true)
    }

    @objc func popoverWillClose(_ notification: Notification) {
        onVisibilityChanged?(false)
    }
}
