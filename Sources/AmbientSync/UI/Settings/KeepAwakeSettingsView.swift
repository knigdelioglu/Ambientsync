import SwiftUI

struct KeepAwakeSettingsView: View {
    @ObservedObject var app: AppState
    @State private var tempCustomMinutes: String = ""
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ekran Açık Kalma Süresi")
                        .font(.headline)
                    Text("Bu süre, son kullanıcı etkinliğinden sonra Mac'in ve isteğe bağlı olarak ekranın ne kadar süre uyanık tutulacağını belirler.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 6)
                
                Toggle("Uyanık tutma özelliğini etkinleştir", isOn: Binding(
                    get: { app.keepAwakeState.featureEnabled },
                    set: { app.setKeepAwakeFeatureEnabled($0) }
                ))
                
                if app.keepAwakeState.featureEnabled {
                    Picker("Varsayılan süre", selection: Binding(
                        get: { app.keepAwakeState.defaultIdleTimeoutMode },
                        set: { app.setKeepAwakeDefaultDurationMode($0) }
                    )) {
                        Text("15 dk").tag("15")
                        Text("30 dk").tag("30")
                        Text("1 sa").tag("60")
                        Text("Asla").tag("never")
                        Text("Özel dakika").tag("custom")
                    }
                    .pickerStyle(.menu)
                    
                    if app.keepAwakeState.defaultIdleTimeoutMode == "custom" {
                        HStack {
                            Text("Özel Süre:")
                                .font(.body)
                            TextField("Dakika", text: $tempCustomMinutes)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                                .onChange(of: tempCustomMinutes) { newValue in
                                    if let val = Int(newValue), val > 0 {
                                        app.setKeepAwakeDefaultCustomMinutes(val)
                                    }
                                }
                            Text("dakika")
                                .font(.body)
                        }
                        .onAppear {
                            tempCustomMinutes = String(app.keepAwakeState.defaultIdleTimeoutMinutes)
                        }
                    }
                    
                    if app.keepAwakeState.defaultIdleTimeoutMode == "never" {
                        Text("Kullanıcı durdurana kadar uyku engellenir.")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }

                    Toggle("Aynı zamanda ekranı açık tut", isOn: Binding(
                        get: { app.keepAwakeState.keepDisplayAwake },
                        set: { app.setKeepAwakeDisplayAwake($0) }
                    ))
                    
                    Toggle("Sadece fişteyken etkinleştir", isOn: Binding(
                        get: { app.keepAwakeState.onlyWhilePluggedIn },
                        set: { app.setKeepAwakePluggedOnly($0) }
                    ))
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Ekran Açık Kalma Süresi")
    }
}
