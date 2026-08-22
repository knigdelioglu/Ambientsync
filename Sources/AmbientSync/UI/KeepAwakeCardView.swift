import SwiftUI

struct KeepAwakeCardView: View {
    @ObservedObject var app: AppState

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    private var defaultDurationText: String {
        let mode = app.keepAwakeState.defaultIdleTimeoutMode
        switch mode {
        case "15": return "15 dk"
        case "30": return "30 dk"
        case "60": return "1 sa"
        case "never": return "Asla"
        case "custom": return "\(app.keepAwakeState.defaultIdleTimeoutMinutes) dk"
        default: return "Bilinmiyor"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 8) {
                Label("Ekranı Açık Tut", systemImage: "cup.and.saucer.fill")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                QuickPanelStatusPill(
                    text: app.isAwakeAssertionActive ? "Aktif" : "Hazır",
                    color: app.isAwakeAssertionActive ? .green : .secondary
                )
            }

            if !app.keepAwakeState.featureEnabled {
                Text("Bu özellik Ayarlar’dan kapatılmış.")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text("Varsayılan")
                            .foregroundStyle(.secondary)
                        Text(defaultDurationText)
                            .fontWeight(.semibold)
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text("Boşta \(app.currentIdleTimeString)")
                            .foregroundStyle(.secondary)
                    }

                    Text(app.remainingIdleTimeString)
                        .foregroundStyle(app.isAwakeAssertionActive ? .primary : .secondary)
                        .lineLimit(1)
                }
                .font(.system(size: 10.5))
                .monospacedDigit()

                LazyVGrid(columns: columns, spacing: 8) {
                    durationButton(title: "Varsayılan", mode: nil)
                    durationButton(title: "15 dakika", mode: "15")
                    durationButton(title: "1 saat", mode: "60")
                    durationButton(title: "Süresiz", mode: "never")
                }

                if app.keepAwakeState.temporaryOverrideActive {
                    Button {
                        withAnimation {
                            app.startSessionWithDefault()
                        }
                    } label: {
                        Label("Geçici ayarı durdur", systemImage: "stop.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .controlSize(.small)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .quickPanelCard()
    }

    private func durationButton(title: String, mode: String?) -> some View {
        let isSelected: Bool = {
            guard app.keepAwakeState.featureEnabled else { return false }
            if let mode {
                return app.keepAwakeState.temporaryOverrideActive && app.keepAwakeState.temporaryIdleTimeoutMode == mode
            }
            return !app.keepAwakeState.temporaryOverrideActive
        }()

        return Button {
            withAnimation {
                if let mode {
                    app.startSessionWithDurationMode(mode)
                } else {
                    app.startSessionWithDefault()
                }
            }
        } label: {
            Text(title)
                .font(.system(size: 10.5, weight: isSelected ? .semibold : .medium))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? .blue : .secondary)
        .controlSize(.small)
        .disabled(!app.keepAwakeState.featureEnabled)
    }
}
