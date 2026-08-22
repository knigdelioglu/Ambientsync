import AppKit
import Foundation
import IOKit
import IOKit.hid
import IOKit.ps
import IOKit.pwr_mgt
import Darwin
import SwiftUI

final class StatusBarView: NSView {
    private let imageView = NSImageView(frame: .zero)
    var onPrimaryClick: (() -> Void)?
    var contextMenu: NSMenu?
    var quickMenu: NSMenu?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = false
        imageView.frame = bounds
        imageView.autoresizingMask = [.width, .height]
        imageView.imageScaling = .scaleProportionallyDown
        addSubview(imageView)
        updateImage(isActive: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool {
        true
    }

    func updateImage(isActive: Bool) {
        let symbolName = isActive ? "sun.max.fill" : "pause.fill"
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        image?.isTemplate = true
        imageView.image = image
        toolTip = isActive ? "AmbientSync running" : "AmbientSync paused"
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 1 {
            onPrimaryClick?()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        showMenu()
    }

    override func otherMouseDown(with event: NSEvent) {
        showMenu()
    }

    private func showMenu() {
        guard let contextMenu else { return }
        let point = NSPoint(x: 0, y: bounds.height)
        contextMenu.popUp(positioning: Optional<NSMenuItem>.none, at: point, in: self)
    }

    func showQuickMenu() {
        guard let quickMenu else { return }
        let point = NSPoint(x: 0, y: bounds.height)
        quickMenu.popUp(positioning: Optional<NSMenuItem>.none, at: point, in: self)
    }
}

final class PowerStatusMenuView: NSView {
    private let iconView = NSImageView(frame: .zero)
    private let label = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 9
        layer?.masksToBounds = true
        layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.10).cgColor

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyDown
        iconView.symbolConfiguration = .init(pointSize: 8.5, weight: .semibold)
        iconView.contentTintColor = .secondaryLabelColor

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 9.5, weight: .semibold)
        label.textColor = .secondaryLabelColor

        addSubview(iconView)
        addSubview(label)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 7),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 9),
            iconView.heightAnchor.constraint(equalToConstant: 9),

            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -7),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(_ state: PowerSourceState) {
        switch state {
        case .ac:
            iconView.image = NSImage(systemSymbolName: "powerplug.fill", accessibilityDescription: nil)
            label.stringValue = "AC"
            layer?.backgroundColor = NSColor.systemGreen.withAlphaComponent(0.14).cgColor
        case .battery:
            iconView.image = NSImage(systemSymbolName: "battery.100", accessibilityDescription: nil)
            label.stringValue = "Battery"
            layer?.backgroundColor = NSColor.systemOrange.withAlphaComponent(0.14).cgColor
        case .unknown:
            iconView.image = NSImage(systemSymbolName: "questionmark", accessibilityDescription: nil)
            label.stringValue = "Power"
            layer?.backgroundColor = NSColor.secondaryLabelColor.withAlphaComponent(0.10).cgColor
        }
    }
}
