import SwiftUI

struct HiDPISettingsView: View {
    @ObservedObject var app: AppState
    
    var body: some View {
        Form {
            Section(header: Text("HiDPI Durumu").font(.headline)) {
                LabeledContent("Durum") {
                    Text(app.isHiDPIActive ? "Etkin" : "Devre Dışı")
                        .fontWeight(.bold)
                        .foregroundStyle(app.isHiDPIActive ? .green : .secondary)
                }
                
                LabeledContent("Mevcut Mod", value: app.hiDPIStatusText)
                LabeledContent("Etkinleştirme Durumu", value: app.hiDPIActivationStatusText)
            }
            
            Section(header: Text("Çözünürlük Denetimi").font(.headline)) {
                HStack(spacing: 12) {
                    Button(action: {
                        app.applyRetinaMode()
                    }) {
                        Label("HiDPI Moduna Geç", systemImage: "display")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    
                    Button(action: {
                        app.disableRetinaMode()
                    }) {
                        Label("Normal Moda Geç", systemImage: "arrow.uturn.backward")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bilgi")
                        .font(.subheadline.weight(.semibold))
                    Text("HiDPI modu, harici Samsung ekranınızda çok daha net bir yazı görüntüsü (Retina ölçekleme) sağlar. Sistem, 2560x1440 mantıksal çözünürlük altında 5120x2880 piksellik pürüzsüz bir işleme gerçekleştirir.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("HiDPI")
    }
}
