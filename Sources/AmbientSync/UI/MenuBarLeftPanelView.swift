import SwiftUI

struct MenuBarLeftPanelView: View {
    @ObservedObject var app: AppState

    @State private var volumeDraft: Double = 0
    @State private var isAdjustingVolume = false
    @State private var volumeTask: Task<Void, Never>? = nil

    private var powerStateText: String {
        switch app.powerSourceController.currentState() {
        case .ac: return "AC (Fiş)"
        case .battery: return "Pil"
        case .unknown: return "Bilinmiyor"
        }
    }

    private var powerIcon: String {
        switch app.powerSourceController.currentState() {
        case .ac: return "powerplug.fill"
        case .battery: return "battery.100"
        default: return "questionmark.circle"
        }
    }

    private var displayedVolume: String {
        if isAdjustingVolume {
            return "\(Int(volumeDraft.rounded()))%"
        }
        return app.currentVolume.map { "\($0)%" } ?? "\(app.monitorVolumeControlValue)%"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    statusBadge(
                        icon: "sun.max.fill",
                        value: app.currentLux.map { String(format: "%.0f lx", $0) } ?? "—",
                        iconColor: .orange
                    )
                    statusBadge(
                        icon: powerIcon,
                        value: powerStateText,
                        iconColor: app.powerSourceController.currentState() == .ac ? .green : .orange
                    )
                    hidpiToggleButton()
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Label("Monitör Sesi", systemImage: "speaker.wave.2.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        QuickPanelValuePill(text: displayedVolume)
                    }

                    HStack(spacing: 9) {
                        Image(systemName: "speaker.fill")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 11))
                            .frame(width: 13)

                        Slider(
                            value: Binding(
                                get: { volumeDraft },
                                set: { newValue in
                                    let intValue = Int(newValue.rounded())
                                    let changed = intValue != Int(volumeDraft.rounded())
                                    volumeDraft = newValue
                                    if changed {
                                        volumeTask?.cancel()
                                        volumeTask = Task { @MainActor in
                                            try? await Task.sleep(nanoseconds: 150_000_000)
                                            guard !Task.isCancelled else { return }
                                            app.setMonitorVolumeForSettings(intValue)
                                        }
                                    }
                                }
                            ),
                            in: 0...100,
                            step: 1,
                            onEditingChanged: { isAdjustingVolume = $0 }
                        )
                        .tint(.blue)

                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 11))
                            .frame(width: 13)
                    }
                }
                .quickPanelCard()

                BrightnessCardView(app: app)
                DisplayConnectionCardView(app: app)
                KeepAwakeCardView(app: app)

                HStack(spacing: 8) {
                    Button(action: app.openSettings) {
                        Label("Ayarlar", systemImage: "gearshape.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)

                    Button(action: { NSApplication.shared.terminate(nil) }) {
                        Label("Çıkış", systemImage: "power")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                }
                .padding(.top, 2)
            }
            .padding(12)
            .frame(width: 312, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .frame(width: 336, height: 640)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.96))
        .onAppear {
            volumeDraft = Double(app.monitorVolumeControlValue)
            isAdjustingVolume = false
        }
        .onChange(of: app.monitorVolumeControlValue) { newValue in
            if !isAdjustingVolume {
                volumeDraft = Double(newValue)
            }
        }
    }

    private func statusBadge(icon: String, value: String, iconColor: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(iconColor)

            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color.primary.opacity(0.045), lineWidth: 1)
        )
    }

    private func hidpiToggleButton() -> some View {
        Button {
            if app.isHiDPIActive {
                app.disableRetinaMode()
            } else {
                app.applyRetinaMode()
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "display")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(app.isHiDPIActive ? .purple : .secondary)

                Text("HiDPI")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(
                (app.isHiDPIActive ? Color.purple.opacity(0.10) : Color.primary.opacity(0.045)),
                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(app.isHiDPIActive ? Color.purple.opacity(0.18) : Color.primary.opacity(0.045), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help(app.isHiDPIActive ? "HiDPI açık, kapatmak için tıkla" : "HiDPI kapalı, açmak için tıkla")
    }
}
