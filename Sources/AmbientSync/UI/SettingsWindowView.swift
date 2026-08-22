import AppKit
import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "Genel"
    case brightness = "Parlaklık"
    case hidpi = "HiDPI"
    case keepAwake = "Uyanık Tut"
    case profiles = "Profiller"
    case calibration = "Kalibrasyon"
    case advanced = "Gelişmiş"
    case diagnostics = "Tanılama"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .brightness: return "sun.max"
        case .hidpi: return "display"
        case .keepAwake: return "timer"
        case .profiles: return "slider.horizontal.3"
        case .calibration: return "slider.horizontal.below.square.filled.and.square"
        case .advanced: return "cpu"
        case .diagnostics: return "wrench.and.screwdriver"
        }
    }
}

struct SettingsWindowView: View {
    @ObservedObject var app: AppState
    @ObservedObject var store: AmbientSyncStore
    @State private var selectedTab: SettingsTab = .general
    
    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(tab.rawValue, systemImage: tab.icon)
                        .font(.body)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
        } detail: {
            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsView(app: app)
                case .brightness:
                    BrightnessSettingsView(app: app, store: store)
                case .hidpi:
                    HiDPISettingsView(app: app)
                case .keepAwake:
                    KeepAwakeSettingsView(app: app)
                case .profiles:
                    ProfilesSettingsView(app: app, store: store)
                case .calibration:
                    CalibrationSettingsView(app: app)
                case .advanced:
                    AdvancedSettingsView(app: app)
                case .diagnostics:
                    DiagnosticsSettingsView(app: app)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 700, minHeight: 480)
    }
}

final class PreferencesWindowController: NSWindowController {
    private let hostingController: NSHostingController<SettingsWindowView>

    init(app: AppState, store: AmbientSyncStore) {
        hostingController = NSHostingController(rootView: SettingsWindowView(app: app, store: store))
        let contentSize = NSSize(width: 750, height: 500)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "AmbientSync Tercihleri"
        window.isOpaque = false
        window.backgroundColor = .windowBackgroundColor
        window.minSize = contentSize
        super.init(window: window)
        window.setContentSize(contentSize)
        window.contentViewController = hostingController
        hostingController.view.frame = NSRect(origin: .zero, size: contentSize)
        hostingController.view.autoresizingMask = [.width, .height]
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrame(NSRect(origin: window.frame.origin, size: contentSize), display: true)
        window.makeKeyAndOrderFront(nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
