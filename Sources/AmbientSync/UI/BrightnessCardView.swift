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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Parlaklık")
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.bottom, 2)
            
            // Dahili Ekran
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Label("Dahili Ekran", systemImage: "laptopcomputer")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text(isAdjustingInternalBrightness ? "\(Int(internalBrightnessDraft.rounded()))%" : (app.currentInternalBrightness.map { "\($0)%" } ?? "—"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "sun.min")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 11))
                    
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
                        onEditingChanged: { isEditing in
                            isAdjustingInternalBrightness = isEditing
                        }
                    )
                    .accentColor(.blue)
                    
                    Image(systemName: "sun.max")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 11))
                }
            }
            
            Divider()
                .padding(.vertical, 2)
            
            // Harici Ekran
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Label("Harici Ekran", systemImage: "desktopcomputer")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text(isAdjustingBrightness ? "\(Int(brightnessDraft.rounded()))%" : "\(app.monitorBrightnessControlValue)%")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "sun.min.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 11))
                    
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
                    .accentColor(.blue)
                    
                    Image(systemName: "sun.max.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 11))
                }
                
                // Harici ekran altı kısa bilgi
                VStack(alignment: .leading, spacing: 4) {
                    if let lux = app.currentLux {
                        HStack(spacing: 4) {
                            Text("Ortam:")
                            Text(String(format: "%.0f lux", lux))
                                .fontWeight(.semibold)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Text("Hedef:")
                            Text("\(app.brightnessState.autoTargetBrightnessPercent.map { "\($0)%" } ?? "—")")
                                .fontWeight(.semibold)
                        }
                        
                        HStack(spacing: 4) {
                            Text("DDC:")
                            Text("\(app.currentBrightness.map { "\($0)%" } ?? "\(app.monitorBrightnessControlValue)%")")
                                .fontWeight(.semibold)
                        }
                    }

                    if let target = app.brightnessState.autoTargetBrightnessPercent ?? app.brightnessState.requestedDDCBrightnessPercent,
                       target == 100,
                       let actual = app.brightnessState.actualDDCBrightnessPercent,
                       actual < 100 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                            Text("Monitör parlaklık komutunu sınırlıyor olabilir.")
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.orange)
                    }
                    
                    if app.brightnessState.showMismatchWarning {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                            Text("Otomatik hedef uygulanmamış görünüyor.")
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.orange)
                    }
                    
                    if let pausedUntil = app.brightnessState.manualOverridePausedUntil, pausedUntil > Date() {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.raised.fill")
                                .font(.caption2)
                            Text("Manual override: Aktif")
                                .fontWeight(.semibold)
                            if !timeRemainingText.isEmpty {
                                Text("(Kalan süre: \(timeRemainingText))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.blue)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
        )
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
