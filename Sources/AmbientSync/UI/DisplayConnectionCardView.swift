import SwiftUI

struct DisplayConnectionCardView: View {
    @ObservedObject var app: AppState
    @ObservedObject private var controller: DisplayConnectionController

    init(app: AppState) {
        self.app = app
        self._controller = ObservedObject(wrappedValue: .shared)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 8) {
                Label("Ekran Bağlantısı", systemImage: statusIcon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                QuickPanelStatusPill(text: statusText, color: statusColor)
            }

            HStack(spacing: 11) {
                Image(systemName: "display")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(statusColor)
                    .frame(width: 34, height: 34)
                    .background(statusColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(controller.snapshot.name)
                        .font(.system(size: 12.5, weight: .semibold))
                        .lineLimit(1)
                    Text(controller.snapshot.message)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Button(action: app.toggleExternalDisplayConnection) {
                    if controller.isBusy {
                        ProgressView()
                            .controlSize(.small)
                            .frame(minWidth: 64)
                    } else {
                        Label(actionTitle, systemImage: actionIcon)
                            .font(.system(size: 11, weight: .semibold))
                            .frame(minWidth: 64)
                    }
                }
                .buttonStyle(.bordered)
                .tint(actionTint)
                .controlSize(.small)
                .disabled(!controller.snapshot.canToggle || controller.isBusy)
            }
        }
        .quickPanelCard()
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

    private var actionIcon: String {
        switch controller.snapshot.phase {
        case .connected:
            return "rectangle.portrait.and.arrow.right"
        case .softwareDisconnected:
            return "arrow.clockwise"
        case .disconnecting, .reconnecting:
            return "arrow.triangle.2.circlepath"
        default:
            return "ellipsis"
        }
    }

    private var actionTint: Color {
        switch controller.snapshot.phase {
        case .softwareDisconnected:
            return .blue
        case .connected:
            return .secondary
        default:
            return statusColor
        }
    }

    private var statusText: String {
        switch controller.snapshot.phase {
        case .connected:
            return "Bağlı"
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
