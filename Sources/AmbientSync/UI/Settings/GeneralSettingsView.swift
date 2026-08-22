import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var app: AppState
    
    private var powerStateText: String {
        switch app.powerSourceController.currentState() {
        case .ac: return "Şebeke Gücü (AC)"
        case .battery: return "Pil (Batarya)"
        case .unknown: return "Bilinmiyor"
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Ekran Bilgileri").font(.headline)) {
                LabeledContent("Aktif Ekran", value: app.currentDisplayLabel)
                if let key = app.currentDisplayKey {
                    LabeledContent("Parmak İzi", value: key)
                }
                LabeledContent("Mevcut Çözünürlük", value: app.hiDPIStatusText)
            }

            Section(header: Text("Menü Çubuğu").font(.headline)) {
                Picker("İkon yanında göster", selection: Binding(
                    get: { app.statusBarDetailMode },
                    set: { app.setStatusBarDetailMode($0) }
                )) {
                    ForEach(StatusBarDetailMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.menu)

                Text(app.statusBarDetailMode.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section(header: Text("Sistem Ayarları").font(.headline)) {
                Toggle("Girişte Otomatik Başlat", isOn: Binding(
                    get: { app.isLaunchAgentInstalled() },
                    set: { _ in app.toggleLaunchAtLogin() }
                ))
                .toggleStyle(.switch)
                
                LabeledContent("Güç Durumu", value: powerStateText)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Genel")
    }
}
