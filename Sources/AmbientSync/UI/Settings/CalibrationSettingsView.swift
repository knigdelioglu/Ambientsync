import SwiftUI

struct CalibrationSettingsView: View {
    @ObservedObject var app: AppState
    
    var body: some View {
        Form {
            Section(header: Text("Ekran Kalibrasyonu").font(.headline)) {
                if let session = app.calibrationSession {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Adım: \(session.stepIndex + 1) / \(session.stepCount)")
                                .font(.headline)
                            Spacer()
                            Text(session.step.rawValue.uppercased())
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        
                        ProgressView(value: Double(session.stepIndex), total: Double(session.stepCount))
                            .tint(.blue)
                        
                        Text(session.instruction)
                            .font(.body)
                            .padding(.vertical, 4)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: 8) {
                            Button(session.captureButtonTitle) {
                                app.captureCalibrationStep()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            
                            Button("Vazgeç") {
                                app.cancelCalibration()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kalibrasyon Sihirbazı")
                            .font(.subheadline.weight(.semibold))
                        
                        Text("Üç farklı ışık seviyesi (karanlık, orta, aydınlık) okuması yaparak ekranınız için en uygun otomatik parlaklık eğrisini oluşturalım.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Button("Kalibrasyonu Başlat") {
                            app.startCalibration()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section(header: Text("Anlık Okumalar").font(.headline)) {
                LabeledContent("Ortam Işığı", value: app.currentLux.map { String(format: "%.0f lux", $0) } ?? "Okunamıyor")
                LabeledContent("Monitör Parlaklığı", value: app.currentBrightness.map { "\($0)%" } ?? "\(app.monitorBrightnessControlValue)%")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Kalibrasyon")
    }
}
