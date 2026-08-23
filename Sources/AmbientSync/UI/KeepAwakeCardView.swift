import SwiftUI

struct KeepAwakeCardView: View {
    @ObservedObject var app: AppState

    @State private var customMinutesText: String = ""

    private let maximumCustomMinutes = 10_080

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            statusOverview

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Hızlı Süre")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    durationSegment(title: "Varsayılan", mode: nil)
                    durationSegment(title: "15 dk", mode: "15")
                    durationSegment(title: "30 dk", mode: "30")
                    durationSegment(title: "1 saat", mode: "60")
                    durationSegment(title: "Süresiz", mode: "never")
                }
                .padding(4)
                .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            manualDurationSection

            if app.keepAwakeState.temporaryOverrideActive {
                Button {
                    withAnimation(.easeOut(duration: 0.12)) {
                        app.startSessionWithDefault()
                    }
                } label: {
                    Label("Varsayılan süreye dön", systemImage: "arrow.uturn.backward")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .quickPanelCard()
        .onChange(of: customMinutesText) { newValue in
            let filtered = String(newValue.filter { $0.isNumber }.prefix(5))
            if filtered != newValue {
                customMinutesText = filtered
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.title3)
                .foregroundStyle(statusColor)
                .frame(width: 36, height: 36)
                .background(statusColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Ekranı Açık Tut")
                    .font(.system(size: 13.5, weight: .semibold))
                Text("Mac’in boşta kaldığında ekran uykusuna geçmesini denetler.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle(
                "",
                isOn: Binding(
                    get: { app.keepAwakeState.featureEnabled },
                    set: { app.setKeepAwakeFeatureEnabled($0) }
                )
            )
            .labelsHidden()
            .toggleStyle(.switch)
        }
    }

    private var statusOverview: some View {
        HStack(spacing: 18) {
            QuickPanelRingGauge(
                value: idleProgress,
                tint: statusColor,
                valueText: ringValueText,
                label: ringLabel
            )
            .frame(width: 92, height: 92)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    QuickPanelStatusPill(text: statusText, color: statusColor)
                    if app.keepAwakeState.temporaryOverrideActive {
                        QuickPanelStatusPill(text: "Geçici", color: .blue)
                    }
                }

                Text(remainingSummary)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(2)

                HStack(spacing: 5) {
                    Text("Boşta")
                        .foregroundStyle(.secondary)
                    Text(app.currentIdleTimeString)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text("Seçim: \(effectiveDurationText)")
                        .foregroundStyle(.secondary)
                }
                .font(.caption2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var manualDurationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Manuel Süre")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("1 dk – 7 gün")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 8) {
                TextField("Örn. 45", text: $customMinutesText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .onSubmit(startCustomDuration)

                Text("dk")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Button(action: startCustomDuration) {
                    Label("Başlat", systemImage: "play.fill")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(customMinutes == nil)
            }

            if let customMinutes {
                Text("Ekran uykusu \(friendlyDuration(customMinutes)) boyunca engellenecek.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if !customMinutesText.isEmpty {
                Text("1 ile \(maximumCustomMinutes) dakika arasında bir değer gir.")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            } else {
                Text("Hazır seçeneklerde olmayan bir süreyi dakika olarak girebilirsin.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        }
    }

    private func durationSegment(title: String, mode: String?) -> some View {
        let isSelected: Bool = {
            guard app.keepAwakeState.featureEnabled else { return false }
            if let mode {
                return app.keepAwakeState.temporaryOverrideActive
                    && app.keepAwakeState.temporaryIdleTimeoutMode == mode
            }
            return !app.keepAwakeState.temporaryOverrideActive
        }()

        return Button {
            withAnimation(.easeOut(duration: 0.12)) {
                ensureFeatureEnabled()
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
                .minimumScaleFactor(0.78)
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    isSelected ? Color.accentColor.opacity(0.16) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }

    private var customMinutes: Int? {
        guard let minutes = Int(customMinutesText), (1...maximumCustomMinutes).contains(minutes) else {
            return nil
        }
        return minutes
    }

    private func startCustomDuration() {
        guard let customMinutes else { return }
        ensureFeatureEnabled()
        withAnimation(.easeOut(duration: 0.12)) {
            app.startSessionWithCustomMinutes(customMinutes)
        }
    }

    private func ensureFeatureEnabled() {
        if !app.keepAwakeState.featureEnabled {
            app.setKeepAwakeFeatureEnabled(true)
        }
    }

    private var defaultDurationText: String {
        switch app.keepAwakeState.defaultIdleTimeoutMode {
        case "15": return "15 dk"
        case "30": return "30 dk"
        case "60": return "1 saat"
        case "never": return "Süresiz"
        case "custom": return friendlyDuration(app.keepAwakeState.defaultIdleTimeoutMinutes)
        default: return "Bilinmiyor"
        }
    }

    private var effectiveDurationText: String {
        guard app.keepAwakeState.temporaryOverrideActive else {
            return defaultDurationText
        }

        switch app.keepAwakeState.temporaryIdleTimeoutMode {
        case "15": return "15 dk"
        case "30": return "30 dk"
        case "60": return "1 saat"
        case "never": return "Süresiz"
        case "custom": return friendlyDuration(app.keepAwakeState.temporaryIdleTimeoutMinutes ?? 15)
        default: return defaultDurationText
        }
    }

    private var statusText: String {
        if !app.keepAwakeState.featureEnabled { return "Kapalı" }
        return app.isAwakeAssertionActive ? "Aktif" : "Hazır"
    }

    private var statusColor: Color {
        if !app.keepAwakeState.featureEnabled { return .secondary }
        return app.isAwakeAssertionActive ? .green : .blue
    }

    private var remainingSummary: String {
        if !app.keepAwakeState.featureEnabled {
            return "Koruma kapalı"
        }
        return app.remainingIdleTimeString
    }

    private var ringValueText: String {
        if !app.keepAwakeState.featureEnabled { return "Kapalı" }
        if effectiveTimeoutSeconds == nil { return "∞" }
        if app.isAwakeAssertionActive { return compactRemainingTime }
        return "Hazır"
    }

    private var ringLabel: String {
        effectiveTimeoutSeconds == nil ? "süresiz" : "kalan"
    }

    private var compactRemainingTime: String {
        let prefix = "Uykuya izin verilmesine: "
        if app.remainingIdleTimeString.hasPrefix(prefix) {
            return String(app.remainingIdleTimeString.dropFirst(prefix.count))
        }
        if app.remainingIdleTimeString == "Süresiz" { return "∞" }
        if app.remainingIdleTimeString == "Güç bekleniyor" { return "Bekle" }
        if app.remainingIdleTimeString == "Uykuya izin verildi" { return "00:00" }
        return "—"
    }

    private var idleProgress: Double {
        guard app.keepAwakeState.featureEnabled else { return 0 }
        guard let timeout = effectiveTimeoutSeconds, timeout > 0 else {
            return app.isAwakeAssertionActive ? 1 : 0
        }
        return min(max(currentIdleSeconds / timeout, 0), 1)
    }

    private var currentIdleSeconds: Double {
        let parts = app.currentIdleTimeString.split(separator: ":")
        guard parts.count == 2,
              let minutes = Double(parts[0]),
              let seconds = Double(parts[1]) else {
            return 0
        }
        return (minutes * 60) + seconds
    }

    private var effectiveTimeoutSeconds: Double? {
        let mode = app.keepAwakeState.temporaryOverrideActive
            ? (app.keepAwakeState.temporaryIdleTimeoutMode ?? "15")
            : app.keepAwakeState.defaultIdleTimeoutMode
        let customMinutes = app.keepAwakeState.temporaryOverrideActive
            ? app.keepAwakeState.temporaryIdleTimeoutMinutes
            : app.keepAwakeState.defaultIdleTimeoutMinutes

        switch mode {
        case "15": return 15 * 60
        case "30": return 30 * 60
        case "60": return 60 * 60
        case "custom": return Double(customMinutes ?? 15) * 60
        case "never": return nil
        default: return 15 * 60
        }
    }

    private func friendlyDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) dk"
        }

        let hours = minutes / 60
        let remainder = minutes % 60
        if remainder == 0 {
            return "\(hours) saat"
        }
        return "\(hours) sa \(remainder) dk"
    }
}
