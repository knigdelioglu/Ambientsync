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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // A. Üst Durum Özeti (Tek Satır)
                HStack(spacing: 6) {
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
                
                // B. Ses Kartı
                VStack(alignment: .leading, spacing: 10) {
                    Text("Ses")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.bottom, 2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label("Monitör Sesi", systemImage: "speaker.wave.2")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(isAdjustingVolume ? "\(Int(volumeDraft.rounded()))%" : (app.currentVolume.map { "\($0)%" } ?? "\(app.monitorVolumeControlValue)%"))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: "speaker.fill")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 11))
                            
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
                                onEditingChanged: { isEditing in
                                    isAdjustingVolume = isEditing
                                }
                            )
                            .accentColor(.blue)
                            
                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 11))
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
                )
                
                // C. Parlaklık Kartı
                BrightnessCardView(app: app)

                // D. Harici Ekran Kartı
                DisplayConnectionCardView(app: app)

                // E. Uyanık Tut Kartı
                KeepAwakeCardView(app: app)

                // F. Alt Kısa Eylemler
                HStack(spacing: 8) {
                    Button(action: {
                        app.openSettings()
                    }) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Ayarlar...")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        HStack {
                            Image(systemName: "power")
                            Text("Çıkış")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding(.top, 4)
            }
            .padding(12)
            .frame(width: 280, alignment: .leading)
        }
        .frame(width: 296, height: 640)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
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
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(iconColor)
            
            Text(value)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
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
            HStack(spacing: 4) {
                Image(systemName: "display")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(app.isHiDPIActive ? .purple : .secondary)

                Text("HiDPI")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(app.isHiDPIActive ? 0.55 : 0.4))
            )
        }
        .buttonStyle(.plain)
        .help(app.isHiDPIActive ? "HiDPI açık, kapatmak için tıkla" : "HiDPI kapalı, açmak için tıkla")
    }
}
