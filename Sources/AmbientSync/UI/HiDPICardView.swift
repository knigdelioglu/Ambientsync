import SwiftUI

struct HiDPICardView: View {
    @ObservedObject var app: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HiDPI")
                .font(.headline)
                .foregroundStyle(.primary)
            
            HStack {
                Text("Durum:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(app.isHiDPIActive ? "Açık" : "Kapalı")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(app.isHiDPIActive ? .green : .secondary)
            }
            
            Text(app.hiDPIStatusText)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 8) {
                Button(action: {
                    app.applyRetinaMode()
                }) {
                    HStack {
                        Image(systemName: "display")
                        Text("HiDPI Aç")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Button(action: {
                    app.disableRetinaMode()
                }) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                        Text("HiDPI Kapat")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .font(.caption.weight(.medium))
            .padding(.top, 4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
        )
    }
}
