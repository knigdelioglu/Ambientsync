import SwiftUI

struct BrightnessCardView: View {
    @ObservedObject var app: AppState

    @State private var internalBrightnessDraft: Double = 0
    @State private var isAdjustingInternalBrightness = false
    @State private var internalBrightnessTask: Task<Void, Never>? = nil

    @State private var brightnessDraft: Double = 0
    @State private var isAdjustingBrightness = false
    @State private var brightnessTask: Task<Void, Never>? = nil

    @State private var timeRemainingText: String = ""
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var internalBrightnessText: String {
        if isAdjustingInternalBrightness {
            return "\(Int(internalBrightnessDraft.rounded()))%"
        }
        return app.currentInternalBrightness.map { "\($0)%" } ?? "—"
    }

    private var externalBrightnessText: String {
        isAdjustingBrightness ? "\(Int(brightnessDraft.rounded()))%" : "\(app.monitorBrightnessControlValue)%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Parlaklık", systemImage: "sun.max.fill")
                .font(.system(size: 13, weight: .semibold))

            QuickPanelInsetSurface {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Image(systemName: "laptopcomputer")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 18)

                        Text("Dahili Ekran")
                            .font(.system(size: 11.5, weight: .medium))

                        Spacer()
                        QuickPanelValuePill(text: internalBrightnessText)
                    }

                    HStack(spacing: 9) {
                        Image(systemName: "sun.min")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 11))
                            .frame(width: 13)

                        Slider(
                            value: Binding(
                                get: { internalBrightnessDraft },
                                set: { newValue in
                                    let intValue = Int(newValue.rounded())
                                    let changed = intValue != Int(internalBrightnessDraft.rounded())
                                    internalBrightnessDraft = newValue
                                    if changed {
                                        internalBrightnessTask?.cancel()
                                        internalBrightnessTask = Task { @MainActor in
                                            try? await Task.sleep(nanoseconds: 50_000_000)
                                            guard !Task.isCancelled else { return }
                                            app.setInternalBrightness(intValue)
                                        }
                                    }
                                }
                            ),
                            in: 0...100,
                            step: 1,
                            onEditingChanged: { isAdjustingInternalBrightness = $0 }
                        )
                        .tint(.blue)

                        Image(systemName: "sun.max")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 11))
                            .frame(width: 13)
                    }
                }
            }

            QuickPanelInsetSurface {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Image(systemName: "desktopcomputer")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 18)

                        Text("Harici Ekran")
                            .font(.system(size: 11.5, weight: .medium))

                        Spacer()
                        QuickPanelValuePill(text: externalBrightnessText)
                    }

                    HStack(spacing: 9) {
                        Image(systemName: "sun.min.fill")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 11))
                            .frame(width: 13)

                        Slider(
                            value: Binding(
                                get: { brightnessDraft },
                                set: { newValue in
                                    let intValue = Int(newValue.rounded())
                                    let changed = intValue != Int(brightnessDraft.rounded())
                                    brightnessDraft = newValue
                                    if changed {
                                        brightnessTask?.cancel()
                                        brightnessTask = Task { @MainActor in
                                            try? await Task.sleep(nanoseconds: 150_000_000)
                                            guard !Task.isCancelled else { return }
                                            app.setMonitorBrightness(intValue)
                                        }
                                    }
                                }
                            ),
                            in: 0...100,
                            step: 1,
                            onEditingChanged: { isEditing in
                                isAdjustingBrightness = isEditing
                                if isEditing {
                                    app.pauseAutoBrightnessTemporarily()
                                }
                            }
                        )
                        .tint(.blue)

                        Image(systemName: "sun.max.fill")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 11))
                            .frame(width: 13)
                    }
                }
            }

            HStack(spacing: 6) {
                QuickPanelMetricTile(
                    label: "Ortam",
                    value: app.currentLux.map { String(format: "%.0f lx", $0) } ?? "—"
                )
                QuickPanelMetricTile(
                    label: "Hedef",
                    value: app.brightnessState.autoTargetBrightnessPercent.map { "\($0)%" } ?? "—"
                )
                QuickPanelMetricTile(
                    label: "DDC",
                    value: app.currentBrightness.map { "\($0)%" } ?? "\(app.monitorBrightnessControlValue)%"
                )
            }

            if let target = app.brightnessState.autoTargetBrightnessPercent ?? app.brightnessState.requestedDDCBrightnessPercent,
               target == 100,
               let actual = app.brightnessState.actualDDCBrightnessPercent,
               actual < 100 {
                warningRow("Monitör parlaklık komutunu sınırlıyor olabilir.")
            }

            if app.brightnessState.showMismatchWarning {
                warningRow("Otomatik hedef uygulanmamış görünüyor.")
            }

            if let pausedUntil = app.brightnessState.manualOverridePausedUntil, pausedUntil > Date() {
                HStack(spacing: 5) {
                    Image(systemName: "hand.raised.fill")
                    Text("Elle ayar aktif")
                        .fontWeight(.medium)
                    if !timeRemainingText.isEmpty {
                        Text("• \(timeRemainingText)")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.system(size: 10))
                .foregroundStyle(.blue)
            }
        }
        .quickPanelCard()
        .onAppear {
            brightnessDraft = Double(app.monitorBrightnessControlValue)
            isAdjustingBrightness = false
            internalBrightnessDraft = Double(app.currentInternalBrightness ?? 50)
            isAdjustingInternalBrightness = false
            updateRemainingTime()
        }
        .onChange(of: app.monitorBrightnessControlValue) { newValue in
            if !isAdjustingBrightness {
                brightnessDraft = Double(newValue)
            }
        }
        .onChange(of: app.currentInternalBrightness) { newValue in
            if !isAdjustingInternalBrightness {
                internalBrightnessDraft = Double(newValue ?? 50)
            }
        }
        .onReceive(timer) { _ in
            updateRemainingTime()
        }
    }

    private func warningRow(_ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(text)
                .fontWeight(.medium)
        }
        .font(.system(size: 10))
        .foregroundStyle(.orange)
    }

    private func updateRemainingTime() {
        if let pausedUntil = app.brightnessState.manualOverridePausedUntil, pausedUntil > Date() {
            let remainingSeconds = Int(pausedUntil.timeIntervalSinceNow)
            let minutes = remainingSeconds / 60
            let seconds = remainingSeconds % 60
            timeRemainingText = minutes > 0 ? "\(minutes)dk \(seconds)sn" : "\(seconds)sn"
        } else {
            timeRemainingText = ""
        }
    }
}
