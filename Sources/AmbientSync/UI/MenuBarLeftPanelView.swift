import SwiftUI

struct MenuBarLeftPanelView: View {
    @ObservedObject var app: AppState
    @ObservedObject private var displayController: DisplayConnectionController

    @State private var route: PanelRoute = .dashboard

    @State private var brightnessDraft: Double = 0
    @State private var isAdjustingBrightness = false
    @State private var brightnessTask: Task<Void, Never>? = nil

    @State private var volumeDraft: Double = 0
    @State private var isAdjustingVolume = false
    @State private var volumeTask: Task<Void, Never>? = nil

    @State private var luxHistory: [Double] = []
    @State private var brightnessHistory: [Double] = []
    @State private var volumeHistory: [Double] = []

    private let dashboardCardHeight: CGFloat = 158

    private enum PanelRoute: Equatable {
        case dashboard
        case brightness
        case audio
        case display
        case keepAwake
    }

    init(app: AppState) {
        self.app = app
        self._displayController = ObservedObject(wrappedValue: .shared)
    }

    var body: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor)
                .opacity(0.98)
                .ignoresSafeArea()

            switch route {
            case .dashboard:
                dashboardView
                    .transition(.opacity)
            case .brightness:
                detailContainer(title: "Parlaklık", symbol: "sun.max.fill") {
                    brightnessDetailView
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            case .audio:
                detailContainer(title: "Monitör Sesi", symbol: "speaker.wave.2.fill") {
                    audioDetailView
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            case .display:
                detailContainer(title: "Ekran", symbol: "display") {
                    displayDetailView
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            case .keepAwake:
                detailContainer(title: "Ekranı Açık Tut", symbol: "cup.and.saucer.fill") {
                    keepAwakeDetailView
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(width: 430, height: 640)
        .animation(.easeInOut(duration: 0.16), value: route)
        .onAppear {
            route = .dashboard
            brightnessDraft = Double(app.monitorBrightnessControlValue)
            volumeDraft = Double(app.monitorVolumeControlValue)
            isAdjustingBrightness = false
            isAdjustingVolume = false
            app.refreshDisplayConnectionState()
            seedHistoryIfNeeded()
        }
        .onChange(of: app.currentLux) { newValue in
            if let newValue {
                appendHistory(&luxHistory, value: newValue)
            }
        }
        .onChange(of: app.monitorBrightnessControlValue) { newValue in
            appendHistory(&brightnessHistory, value: Double(newValue))
            if !isAdjustingBrightness {
                brightnessDraft = Double(newValue)
            }
        }
        .onChange(of: app.currentVolume) { newValue in
            if let newValue {
                appendHistory(&volumeHistory, value: Double(newValue))
            }
            if !isAdjustingVolume {
                volumeDraft = Double(newValue ?? app.monitorVolumeControlValue)
            }
        }
        .onChange(of: app.monitorVolumeControlValue) { newValue in
            if !isAdjustingVolume {
                volumeDraft = Double(newValue)
            }
        }
    }

    // MARK: - Dashboard

    private var dashboardView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                dashboardHeader

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                    ],
                    spacing: 12
                ) {
                    ambientLightDashboardCard
                    brightnessDashboardCard
                    audioDashboardCard
                    displayDashboardCard
                }

                keepAwakeDashboardCard
                dashboardFooter
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
    }

    private var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text("AmbientSync")
                    .font(.title3.weight(.semibold))

                Text(brightnessHealthText)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(brightnessHealthColor)

                Spacer()

                Text(displayedBrightness)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Label(
                    app.currentLux.map { String(format: "%.0f lx", $0) } ?? "Sensör bekleniyor",
                    systemImage: "sun.min.fill"
                )
                Text("•")
                    .foregroundStyle(.tertiary)
                Label(powerStateText, systemImage: powerIcon)
                Spacer()
                if app.isHiDPIActive {
                    Label("HiDPI", systemImage: "sparkles.rectangle.stack")
                        .foregroundStyle(.purple)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var ambientLightDashboardCard: some View {
        dashboardCard(accent: .orange) {
            cardHeader(symbol: "sun.max.fill", accent: .orange, destination: .brightness)

            Text("Ortam Işığı")
                .font(.subheadline.weight(.semibold))

            Text(app.currentLux.map { String(format: "%.0f lx", $0) } ?? "—")
                .font(.headline.monospacedDigit())
                .lineLimit(1)

            QuickPanelSparkline(values: luxHistory, tint: .orange)
                .frame(height: 30)

            Text("Sensörden canlı ölçüm")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var brightnessDashboardCard: some View {
        dashboardCard(accent: .blue) {
            cardHeader(symbol: "display.2", accent: .blue, destination: .brightness)

            Text("Parlaklık")
                .font(.subheadline.weight(.semibold))

            Text(displayedBrightness)
                .font(.headline.monospacedDigit())
                .lineLimit(1)

            HStack(spacing: 7) {
                Image(systemName: "sun.min.fill")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Slider(
                    value: Binding(
                        get: { brightnessDraft },
                        set: { newValue in
                            let intValue = Int(newValue.rounded())
                            let changed = intValue != Int(brightnessDraft.rounded())
                            brightnessDraft = newValue

                            if changed {
                                brightnessTask?.cancel()
                                brightnessTask = Task { @MainActor in
                                    try? await Task.sleep(nanoseconds: 120_000_000)
                                    guard !Task.isCancelled else { return }
                                    app.setMonitorBrightness(intValue)
                                }
                            }
                        }
                    ),
                    in: 0...100,
                    step: 1,
                    onEditingChanged: { isEditing in
                        isAdjustingBrightness = isEditing
                        if isEditing {
                            app.pauseAutoBrightnessTemporarily()
                        }
                    }
                )
                .tint(.blue)
                .controlSize(.small)

                Image(systemName: "sun.max.fill")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(height: 30)

            Text(brightnessModuleDetail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var audioDashboardCard: some View {
        dashboardCard(accent: .purple) {
            cardHeader(symbol: "speaker.wave.2.fill", accent: .purple, destination: .audio)

            Text("Monitör Sesi")
                .font(.subheadline.weight(.semibold))

            Text(displayedVolume)
                .font(.headline.monospacedDigit())
                .lineLimit(1)

            HStack(spacing: 7) {
                Image(systemName: "speaker.fill")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Slider(
                    value: Binding(
                        get: { volumeDraft },
                        set: { newValue in
                            let intValue = Int(newValue.rounded())
                            let changed = intValue != Int(volumeDraft.rounded())
                            volumeDraft = newValue

                            if changed {
                                volumeTask?.cancel()
                                volumeTask = Task { @MainActor in
                                    try? await Task.sleep(nanoseconds: 120_000_000)
                                    guard !Task.isCancelled else { return }
                                    app.setMonitorVolumeForSettings(intValue)
                                }
                            }
                        }
                    ),
                    in: 0...100,
                    step: 1,
                    onEditingChanged: { isAdjustingVolume = $0 }
                )
                .tint(.purple)
                .controlSize(.small)

                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(height: 30)

            Text("DDC ses kontrolü")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var displayDashboardCard: some View {
        dashboardCard(accent: displayStatusColor) {
            cardHeader(symbol: displayStatusIcon, accent: displayStatusColor, destination: .display)

            Text("Ekran")
                .font(.subheadline.weight(.semibold))

            Text(displayStatusText)
                .font(.headline)
                .lineLimit(1)

            HStack(spacing: 8) {
                ProgressView(value: Double(app.monitorBrightnessControlValue), total: 100)
                    .progressViewStyle(.linear)
                    .tint(.blue)

                Text("\(app.monitorBrightnessControlValue)%")
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(height: 30)

            Text(displayCardDetail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private func dashboardCard<Content: View>(
        accent: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: dashboardCardHeight, maxHeight: dashboardCardHeight, alignment: .topLeading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        }
    }

    private func cardHeader(symbol: String, accent: Color, destination: PanelRoute) -> some View {
        HStack {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(accent)

            Spacer()

            Button {
                route = destination
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Ayrıntıları aç")
        }
        .frame(height: 24)
    }

    private var keepAwakeDashboardCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.title3)
                    .foregroundStyle(keepAwakeColor)
                    .frame(width: 34, height: 34)
                    .background(keepAwakeColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Ekranı Açık Tut")
                        .font(.subheadline.weight(.semibold))
                    Text(keepAwakeSummaryText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                QuickPanelStatusPill(text: keepAwakeStatusText, color: keepAwakeColor)

                Button {
                    route = .keepAwake
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .frame(width: 28, height: 28)
                        .background(Color.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Süre ve ayrıntılar")
            }

            HStack(spacing: 6) {
                awakePresetButton(title: "15 dk", mode: "15")
                awakePresetButton(title: "30 dk", mode: "30")
                awakePresetButton(title: "1 saat", mode: "60")
                awakePresetButton(title: "Süresiz", mode: "never")
                customAwakeButton
            }
            .padding(4)
            .background(Color.primary.opacity(0.032), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(Color.primary.opacity(0.04), lineWidth: 1)
            }
        }
        .quickPanelCard()
    }

    private func awakePresetButton(title: String, mode: String) -> some View {
        let isSelected = app.keepAwakeState.temporaryOverrideActive
            && app.keepAwakeState.temporaryIdleTimeoutMode == mode

        return Button {
            if !app.keepAwakeState.featureEnabled {
                app.setKeepAwakeFeatureEnabled(true)
            }
            app.startSessionWithDurationMode(mode)
        } label: {
            Text(title)
                .font(.caption2.weight(isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? keepAwakeColor : Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 28)
                .background(
                    isSelected ? keepAwakeColor.opacity(0.14) : Color.primary.opacity(0.035),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            isSelected ? keepAwakeColor.opacity(0.30) : Color.primary.opacity(0.035),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
    }

    private var customAwakeButton: some View {
        let isSelected = app.keepAwakeState.temporaryOverrideActive
            && app.keepAwakeState.temporaryIdleTimeoutMode == "custom"

        return Button {
            route = .keepAwake
        } label: {
            Text("Özel")
                .font(.caption2.weight(isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? keepAwakeColor : Color.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 28)
                .background(
                    isSelected ? keepAwakeColor.opacity(0.14) : Color.primary.opacity(0.035),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            isSelected ? keepAwakeColor.opacity(0.30) : Color.primary.opacity(0.035),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
        .help("Özel süre gir")
    }

    private var dashboardFooter: some View {
        HStack(spacing: 10) {
            Button(action: app.openSettings) {
                Label("Ayarlar", systemImage: "gearshape.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Label("Çıkış", systemImage: "power")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
        }
        .controlSize(.small)
    }

    // MARK: - Detail routes

    private func detailContainer<Content: View>(
        title: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button {
                    route = .dashboard
                } label: {
                    Label("Geri", systemImage: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 10)
                        .frame(minWidth: 72, minHeight: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                Label(title, systemImage: symbol)
                    .font(.headline)

                Spacer()

                Button(action: app.openSettings) {
                    Image(systemName: "gearshape")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .help("Ayarlar")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            Divider()

            content()
        }
    }

    private var brightnessDetailView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                liveBrightnessChart
                BrightnessCardView(app: app)
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
    }

    private var liveBrightnessChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Canlı Eğilim", systemImage: "chart.xyaxis.line")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("son \(max(luxHistory.count, brightnessHistory.count)) örnek")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Label("Ortam ışığı", systemImage: "circle.fill")
                        .foregroundStyle(.orange)
                    Spacer()
                    Text(app.currentLux.map { String(format: "%.0f lx", $0) } ?? "—")
                        .monospacedDigit()
                }
                .font(.caption)

                QuickPanelSparkline(values: luxHistory, tint: .orange)
                    .frame(height: 48)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Label("Harici parlaklık", systemImage: "circle.fill")
                        .foregroundStyle(.blue)
                    Spacer()
                    Text("\(app.monitorBrightnessControlValue)%")
                        .monospacedDigit()
                }
                .font(.caption)

                QuickPanelSparkline(values: brightnessHistory, tint: .blue, fixedRange: 0...100)
                    .frame(height: 48)
            }
        }
        .quickPanelCard()
    }

    private var audioDetailView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Canlı Ses Seviyesi", systemImage: "waveform")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        QuickPanelValuePill(text: displayedVolume, tint: .purple)
                    }

                    QuickPanelSparkline(values: volumeHistory, tint: .purple, fixedRange: 0...100)
                        .frame(height: 68)
                }
                .quickPanelCard()

                audioControlCard
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
    }

    private var audioControlCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Label("Monitör Sesi", systemImage: "speaker.wave.2.fill")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                QuickPanelValuePill(text: displayedVolume, tint: .purple)
            }

            HStack(spacing: 10) {
                Image(systemName: "speaker.fill")
                    .foregroundStyle(.tertiary)

                Slider(
                    value: Binding(
                        get: { volumeDraft },
                        set: { newValue in
                            let intValue = Int(newValue.rounded())
                            let changed = intValue != Int(volumeDraft.rounded())
                            volumeDraft = newValue
                            if changed {
                                volumeTask?.cancel()
                                volumeTask = Task { @MainActor in
                                    try? await Task.sleep(nanoseconds: 120_000_000)
                                    guard !Task.isCancelled else { return }
                                    app.setMonitorVolumeForSettings(intValue)
                                }
                            }
                        }
                    ),
                    in: 0...100,
                    step: 1,
                    onEditingChanged: { isAdjustingVolume = $0 }
                )
                .tint(.purple)

                Image(systemName: "speaker.wave.3.fill")
                    .foregroundStyle(.tertiary)
            }
        }
        .quickPanelCard()
    }

    private var displayDetailView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                DisplayConnectionCardView(app: app)
                HiDPICardView(app: app)
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
    }

    private var keepAwakeDetailView: some View {
        ScrollView {
            KeepAwakeCardView(app: app)
                .padding(16)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Derived UI state

    private var displayedBrightness: String {
        if isAdjustingBrightness {
            return "\(Int(brightnessDraft.rounded()))%"
        }
        return "\(app.monitorBrightnessControlValue)%"
    }

    private var displayedVolume: String {
        if isAdjustingVolume {
            return "\(Int(volumeDraft.rounded()))%"
        }
        return app.currentVolume.map { "\($0)%" } ?? "\(app.monitorVolumeControlValue)%"
    }

    private var brightnessModuleDetail: String {
        if app.brightnessState.isManualOverrideActive {
            return "Manuel ayar aktif"
        }
        if let target = app.brightnessState.autoTargetBrightnessPercent {
            return "Otomatik hedef \(target)%"
        }
        return "Otomatik parlaklık"
    }

    private var brightnessHealthText: String {
        if app.brightnessState.showMismatchWarning {
            return "Dikkat"
        }
        if app.brightnessState.isManualOverrideActive {
            return "Manuel"
        }
        return "Otomatik"
    }

    private var brightnessHealthColor: Color {
        if app.brightnessState.showMismatchWarning { return .orange }
        if app.brightnessState.isManualOverrideActive { return .blue }
        return .green
    }

    private var powerStateText: String {
        switch app.powerSourceController.currentState() {
        case .ac: return "Fişte"
        case .battery: return "Pil"
        case .unknown: return "Güç —"
        }
    }

    private var powerIcon: String {
        switch app.powerSourceController.currentState() {
        case .ac: return "powerplug.fill"
        case .battery: return "battery.100"
        case .unknown: return "questionmark.circle"
        }
    }

    private var displayStatusText: String {
        switch displayController.snapshot.phase {
        case .connected: return "Bağlı"
        case .softwareDisconnected: return "Ayrıldı"
        case .physicallyDisconnected: return "Bağlı değil"
        case .disconnecting: return "Ayırılıyor"
        case .reconnecting: return "Bağlanıyor"
        case .unsupported: return "Destek yok"
        case .failed: return "Hata"
        }
    }

    private var displayStatusIcon: String {
        switch displayController.snapshot.phase {
        case .connected: return "display"
        case .softwareDisconnected: return "display.slash"
        case .disconnecting, .reconnecting: return "arrow.triangle.2.circlepath"
        case .physicallyDisconnected: return "cable.connector.slash"
        case .unsupported, .failed: return "exclamationmark.triangle"
        }
    }

    private var displayStatusColor: Color {
        switch displayController.snapshot.phase {
        case .connected: return .green
        case .softwareDisconnected: return .orange
        case .disconnecting, .reconnecting: return .blue
        case .physicallyDisconnected, .unsupported: return .secondary
        case .failed: return .red
        }
    }

    private var displayCardDetail: String {
        let hidpi = app.isHiDPIActive ? "HiDPI açık" : "HiDPI kapalı"
        let name = displayController.snapshot.name
        if name.isEmpty {
            return hidpi
        }
        return "\(name) · \(hidpi)"
    }

    private var keepAwakeStatusText: String {
        if !app.keepAwakeState.featureEnabled { return "Kapalı" }
        return app.isAwakeAssertionActive ? "Aktif" : "Hazır"
    }

    private var keepAwakeColor: Color {
        if !app.keepAwakeState.featureEnabled { return .secondary }
        return app.isAwakeAssertionActive ? .green : .blue
    }

    private var keepAwakeSummaryText: String {
        if !app.keepAwakeState.featureEnabled {
            return "Süre seçerek doğrudan başlatabilirsin"
        }
        if app.keepAwakeState.temporaryOverrideActive {
            return app.remainingIdleTimeString
        }
        return "Varsayılan: \(defaultAwakeDurationText)"
    }

    private var defaultAwakeDurationText: String {
        switch app.keepAwakeState.defaultIdleTimeoutMode {
        case "15": return "15 dk"
        case "30": return "30 dk"
        case "60": return "1 saat"
        case "never": return "Süresiz"
        case "custom": return "\(app.keepAwakeState.defaultIdleTimeoutMinutes) dk"
        default: return "—"
        }
    }

    // MARK: - History

    private func seedHistoryIfNeeded() {
        if luxHistory.isEmpty, let lux = app.currentLux {
            luxHistory = [lux]
        }
        if brightnessHistory.isEmpty {
            brightnessHistory = [Double(app.monitorBrightnessControlValue)]
        }
        if volumeHistory.isEmpty {
            volumeHistory = [Double(app.currentVolume ?? app.monitorVolumeControlValue)]
        }
    }

    private func appendHistory(_ history: inout [Double], value: Double) {
        if history.last == value, history.count > 1 {
            return
        }
        history.append(value)
        if history.count > 36 {
            history.removeFirst(history.count - 36)
        }
    }
}
