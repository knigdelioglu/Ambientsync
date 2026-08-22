import SwiftUI

struct ProfilesSettingsView: View {
    @ObservedObject var app: AppState
    @ObservedObject var store: AmbientSyncStore
    
    private var displayKey: String { app.activeDisplayKey }
    private var selectedProfile: AmbientSyncProfile {
        store.profile(id: store.selectedProfileID(for: displayKey))
    }
    
    var body: some View {
        Form {
            Section(header: Text("Profil Seçimi ve Adı").font(.headline)) {
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
                .pickerStyle(.menu)
                
                TextField("Profil Adı", text: profileNameBinding)
                    .textFieldStyle(.roundedBorder)
            }
            
            Section(header: Text("Profil Değerleri").font(.headline)) {
                sliderRow(title: "Düşük Işık", value: intBinding(\.lowBrightness), range: 0...40)
                sliderRow(title: "Orta Işık", value: intBinding(\.midBrightness), range: 10...75)
                sliderRow(title: "Yüksek Işık", value: intBinding(\.highBrightness), range: 20...100)
                sliderRow(title: "Tepki Hızı", value: doubleBinding(\.smoothing), range: 0.05...0.85, step: 0.01)
                sliderRow(title: "Eşik (Threshold)", value: intBinding(\.updateThreshold), range: 1...10)
                sliderRow(title: "Aralık (Interval)", value: doubleBinding(\.minInterval), range: 0.3...8.0, step: 0.1)
            }
            
            Section(header: Text("Eylemler").font(.headline)) {
                HStack(spacing: 8) {
                    Button("Kopyala") {
                        store.duplicateProfile(from: selectedProfile, named: "\(selectedProfile.name) Kopyası")
                    }
                    
                    Button("Sıfırla") {
                        store.resetProfile(id: selectedProfile.id)
                    }
                    
                    Spacer()
                    
                    Button(role: .destructive, action: {
                        store.deleteProfile(id: selectedProfile.id)
                    }) {
                        Label("Profili Sil", systemImage: "trash")
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Profiller")
    }
    
    private func sliderRow(title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .frame(width: 100, alignment: .leading)
                .font(.subheadline)
            Slider(value: Binding(
                get: { Double(value.wrappedValue) },
                set: { value.wrappedValue = Int($0.rounded()) }
            ), in: Double(range.lowerBound)...Double(range.upperBound), step: 1)
            Text("\(value.wrappedValue)")
                .frame(width: 34, alignment: .trailing)
                .monospacedDigit()
                .font(.subheadline.bold())
        }
    }
    
    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .frame(width: 100, alignment: .leading)
                .font(.subheadline)
            Slider(value: value, in: range, step: step)
            Text(String(format: "%.2f", value.wrappedValue))
                .frame(width: 52, alignment: .trailing)
                .monospacedDigit()
                .font(.subheadline.bold())
        }
    }
    
    private func intBinding(_ keyPath: WritableKeyPath<AmbientSyncProfile, Int>) -> Binding<Int> {
        Binding(
            get: { selectedProfile[keyPath: keyPath] },
            set: { newValue in
                var profile = selectedProfile
                profile[keyPath: keyPath] = newValue
                store.updateProfile(profile)
            }
        )
    }
    
    private func doubleBinding(_ keyPath: WritableKeyPath<AmbientSyncProfile, Double>) -> Binding<Double> {
        Binding(
            get: { selectedProfile[keyPath: keyPath] },
            set: { newValue in
                var profile = selectedProfile
                profile[keyPath: keyPath] = newValue
                store.updateProfile(profile)
            }
        )
    }
    
    private var profileNameBinding: Binding<String> {
        Binding(
            get: { selectedProfile.name },
            set: { newValue in
                var profile = selectedProfile
                profile.name = newValue
                store.updateProfile(profile)
            }
        )
    }
}
