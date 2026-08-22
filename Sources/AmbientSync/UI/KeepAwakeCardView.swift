import SwiftUI

struct KeepAwakeCardView: View {
    @ObservedObject var app: AppState
    
    private var defaultDurationText: String {
        let mode = app.keepAwakeState.defaultIdleTimeoutMode
        switch mode {
        case "15": return "15 dk"
        case "30": return "30 dk"
        case "60": return "1 sa"
        case "never": return "Asla"
        case "custom": return "\(app.keepAwakeState.defaultIdleTimeoutMinutes) dk"
        default: return "Bilinmiyor"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ekranı Açık Tut")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if !app.keepAwakeState.featureEnabled {
                        Text("Ekran açık kalma özelliği kapalı")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Varsayılan: \(defaultDurationText)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 4) {
                                Text("Boşta: \(app.currentIdleTimeString)")
                                    .font(.caption2)
                                Text("•")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(app.remainingIdleTimeString)
                                    .font(.caption2)
                                    .foregroundStyle(app.isAwakeAssertionActive ? .primary : .secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                if app.isAwakeAssertionActive {
                    Text("Aktif")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                }
            }
            
            Divider()
                .opacity(0.4)
            
            HStack(spacing: 8) {
                Button(action: {
                    withAnimation {
                        app.startSessionWithDefault()
                    }
                }) {
                    Text("Varsayılanı Kullan")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(app.keepAwakeState.temporaryOverrideActive == false && app.keepAwakeState.featureEnabled ? .blue : nil)
                .disabled(!app.keepAwakeState.featureEnabled)
                
                Button(action: {
                    withAnimation {
                        app.startSessionWithDurationMode("15")
                    }
                }) {
                    Text("15 dk")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(app.keepAwakeState.temporaryOverrideActive && app.keepAwakeState.temporaryIdleTimeoutMode == "15" ? .blue : nil)
                .disabled(!app.keepAwakeState.featureEnabled)
                
                Button(action: {
                    withAnimation {
                        app.startSessionWithDurationMode("60")
                    }
                }) {
                    Text("1 sa")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(app.keepAwakeState.temporaryOverrideActive && app.keepAwakeState.temporaryIdleTimeoutMode == "60" ? .blue : nil)
                .disabled(!app.keepAwakeState.featureEnabled)
                
                Button(action: {
                    withAnimation {
                        app.startSessionWithDurationMode("never")
                    }
                }) {
                    Text("Asla")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(app.keepAwakeState.temporaryOverrideActive && app.keepAwakeState.temporaryIdleTimeoutMode == "never" ? .blue : nil)
                .disabled(!app.keepAwakeState.featureEnabled)
            }
            .font(.caption)
            
            if app.keepAwakeState.temporaryOverrideActive {
                Button(action: {
                    withAnimation {
                        app.startSessionWithDefault()
                    }
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Durdur")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .font(.caption.weight(.semibold))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
        )
    }
}
