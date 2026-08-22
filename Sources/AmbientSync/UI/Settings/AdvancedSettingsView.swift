import SwiftUI

struct AdvancedSettingsView: View {
    @ObservedObject var app: AppState
    
    var body: some View {
        Form {
            Section(header: Text("Monitör Ses Ayarları").font(.headline)) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Monitör Ses Seviyesi")
                        Spacer()
                        Text(app.currentVolume.map { "\($0)%" } ?? "\(app.monitorVolumeControlValue)%")
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(app.monitorVolumeControlValue) },
                            set: { app.setMonitorVolumeForSettings(Int($0.rounded())) }
                        ),
                        in: 0...100,
                        step: 1
                    )
                    .accentColor(.blue)
                }
                
                HStack(spacing: 8) {
                    Button("-5") { app.adjustMonitorVolumeForSettings(by: -5) }
                    Button("Sessiz") { app.toggleMuteForSettingsSync() }
                    Button("+5") { app.adjustMonitorVolumeForSettings(by: 5) }
                    Button("%50 Yap") { app.setMonitorVolumeForSettings(50) }
                }
                .buttonStyle(.bordered)
            }
            
            Section(header: Text("Çalışma Davranışları").font(.headline)) {
                VStack(alignment: .leading, spacing: 6) {
                    bulletPoint(text: "Parlaklık, ortam ışığı değiştiğinde otomatik olarak ve seçilen profile uygun hızda güncellenir.")
                    bulletPoint(text: "Kullanıcı parlaklık sürgüsünü elle değiştirdiğinde, otomatik parlaklık geçici bir süre askıya alınır.")
                    bulletPoint(text: "Uyanık tutma ayarları, sistemin veya ekranın uykuya geçmesini önlemek için macOS sistem yetkilerini kullanır.")
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Gelişmiş")
    }
    
    private func bulletPoint(text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .fontWeight(.bold)
                .foregroundStyle(.blue)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
