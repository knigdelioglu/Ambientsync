import SwiftUI

struct KeepAwakeCardView: View {
    @ObservedObject var app: AppState

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

    private var statusText: String {
        if !app.keepAwakeState.featureEnabled { return "Kapalı" }
        return app.isAwakeAssertionActive ? "Aktif" : "Hazır"
    }

    private var statusColor: Color {
        if !app.keepAwakeState.featureEnabled { return .secondary }
        return app.isAwakeAssertionActive ? .green : .secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label("Ekranı Açık Tut", systemImage: "cup.and.saucer.fill")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                QuickPanelStatusPill(text: statusText, color: statusColor)
            }

            if !app.keepAwakeState.featureEnabled {
                Text("Bu özellik Ayarlar’dan kapatılmış.")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 5) {
                    Text("Varsayılan \(defaultDurationText)")
                        .fontWeight(.semibold)
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text("Boşta \(app.currentIdleTimeString)")
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 4)
                }
                .font(.system(size: 10.5))
                .monospacedDigit()

                Text(app.remainingIdleTimeString)
                    .font(.system(size: 10))
                    .foregroundStyle(app.isAwakeAssertionActive ? .primary : .secondary)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    durationSegment(title: "Varsayılan", mode: nil)
                    durationSegment(title: "15 dk", mode: "15")
                    durationSegment(title: "1 sa", mode: "60")
                    durationSegment(title: "Süresiz", mode: "never")
                }
                .padding(4)
                .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                if app.keepAwakeState.temporaryOverrideActive {
                    Button {
                        withAnimation {
                            app.startSessionWithDefault()
                        }
                    } label: {
                        Label("Geçici ayarı durdur", systemImage: "stop.fill")
                            .font(.system(size: 10.5, weight: .semibold))
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

    private func durationSegment(title: String, mode: String?) -> some View {
        let isSelected: Bool = {
            guard app.keepAwakeState.featureEnabled else { return false }
            if let mode {
                return app.keepAwakeState.temporaryOverrideActive && app.keepAwakeState.temporaryIdleTimeoutMode == mode
            }
            return !app.keepAwakeState.temporaryOverrideActive
        }()

        return Button {
            withAnimation(.easeOut(duration: 0.12)) {
                if let mode {
                    app.startSessionWithDurationMode(mode)
                } else {
                    app.startSessionWithDefault()
                }
            }
        } label: {
            Text(title)
                .font(.system(size: 9.5, weight: isSelected ? .semibold : .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(
                    isSelected ? Color.accentColor.opacity(0.16) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .disabled(!app.keepAwakeState.featureEnabled)
    }
}
