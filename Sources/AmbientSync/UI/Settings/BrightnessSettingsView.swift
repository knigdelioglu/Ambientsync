import SwiftUI

struct BrightnessSettingsView: View {
    @ObservedObject var app: AppState
    @ObservedObject var store: AmbientSyncStore
    
    private var displayKey: String { app.activeDisplayKey }
    private var selectedProfile: AmbientSyncProfile {
        store.profile(id: store.selectedProfileID(for: displayKey))
    }
    
    var body: some View {
        Form {
            Section(header: Text("Parlaklık Düzeyleri").font(.headline)) {
                // Dahili Ekran
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Dahili Ekran Parlaklığı")
                        Spacer()
                        Text(app.currentInternalBrightness.map { "\($0)%" } ?? "—")
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(app.currentInternalBrightness ?? 50) },
                            set: { app.setInternalBrightness(Int($0.rounded())) }
                        ),
                        in: 0...100,
                        step: 1
                    )
                    .accentColor(.blue)
                }
                
                // Harici Ekran
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Harici Ekran Parlaklığı")
                        Spacer()
                        Text("\(app.monitorBrightnessControlValue)%")
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(app.monitorBrightnessControlValue) },
                            set: {
                                app.pauseAutoBrightnessTemporarily()
                                app.setMonitorBrightness(Int($0.rounded()))
                            }
                        ),
                        in: 0...100,
                        step: 1
                    )
                    .accentColor(.blue)
                }
            }
            
            Section(header: Text("Otomatik Parlaklık & Profil").font(.headline)) {
                Picker("Aktif Profil", selection: Binding(
                    get: { store.selectedProfileID(for: displayKey) },
                    set: { newValue in
                        store.setSelectedProfileID(newValue, for: displayKey)
                        app.refreshRuntimeState()
                    }
                )) {
                    ForEach(store.preferences.profiles, id: \.id) { profile in
                        Text(profile.name).tag(profile.id)
                    }
                }
                
                LabeledContent("Profil Özeti", value: "Düşük: %\(selectedProfile.lowBrightness) · Orta: %\(selectedProfile.midBrightness) · Yüksek: %\(selectedProfile.highBrightness)")
                
                LabeledContent("Otomatik Parlaklık Durumu") {
                    Text(app.calibrationSession == nil && !app.brightnessState.isManualOverrideActive ? "Aktif" : "Pasif (Manuel / Kalibrasyon)")
                        .fontWeight(.semibold)
                        .foregroundStyle(app.calibrationSession == nil && !app.brightnessState.isManualOverrideActive ? .green : .orange)
                }
            }
            
            Section(header: Text("Sensör Verileri").font(.headline)) {
                LabeledContent("Ortam Işığı", value: app.currentLux.map { String(format: "%.1f lux", $0) } ?? "Okunamıyor")
                LabeledContent("Hesaplanan Hedef", value: app.brightnessState.autoTargetBrightnessPercent.map { "\($0)%" } ?? "—")
                LabeledContent("DDC Okuma", value: app.currentBrightness.map { "\($0)%" } ?? "\(app.monitorBrightnessControlValue)%")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Parlaklık")
    }
}
