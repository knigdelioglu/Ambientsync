import SwiftUI

struct DisplayConnectionCardView: View {
    @ObservedObject var app: AppState
    @ObservedObject private var controller: DisplayConnectionController

    init(app: AppState) {
        self.app = app
        self._controller = ObservedObject(wrappedValue: .shared)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Harici Ekran", systemImage: statusIcon)
                    .font(.headline)
                Spacer()
                Text(statusText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(controller.snapshot.name)
                        .font(.subheadline.weight(.medium))
                    Text(controller.snapshot.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Button(action: app.toggleExternalDisplayConnection) {
                    if controller.isBusy {
                        ProgressView()
                            .controlSize(.small)
                            .frame(minWidth: 54)
                    } else {
                        Text(actionTitle)
                            .frame(minWidth: 54)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!controller.snapshot.canToggle || controller.isBusy)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
        )
        .onAppear {
            app.refreshDisplayConnectionState()
        }
    }

    private var actionTitle: String {
        switch controller.snapshot.phase {
        case .connected:
            return "Ayır"
        case .softwareDisconnected:
            return "Bağla"
        case .disconnecting:
            return "Ayırılıyor"
        case .reconnecting:
            return "Bağlanıyor"
        default:
            return "Bekle"
        }
    }

    private var statusText: String {
        switch controller.snapshot.phase {
        case .connected:
            return "Açık"
        case .softwareDisconnected:
            return "Ayrıldı"
        case .physicallyDisconnected:
            return "Bağlı değil"
        case .disconnecting:
            return "Ayırılıyor"
        case .reconnecting:
            return "Bağlanıyor"
        case .unsupported:
            return "Destek yok"
        case .failed:
            return "Hata"
        }
    }

    private var statusIcon: String {
        switch controller.snapshot.phase {
        case .connected:
            return "display"
        case .softwareDisconnected:
            return "display.slash"
        case .disconnecting, .reconnecting:
            return "arrow.triangle.2.circlepath"
        case .physicallyDisconnected:
            return "cable.connector.slash"
        case .unsupported, .failed:
            return "exclamationmark.triangle"
        }
    }

    private var statusColor: Color {
        switch controller.snapshot.phase {
        case .connected:
            return .green
        case .softwareDisconnected:
            return .orange
        case .disconnecting, .reconnecting:
            return .blue
        case .physicallyDisconnected, .unsupported:
            return .secondary
        case .failed:
            return .red
        }
    }
}
