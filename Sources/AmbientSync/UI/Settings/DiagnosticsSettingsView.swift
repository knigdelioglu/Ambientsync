import SwiftUI

struct DiagnosticsSettingsView: View {
    @ObservedObject var app: AppState
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Keep Awake (Uyanık Tutma) Durumu
                VStack(alignment: .leading, spacing: 6) {
                    Text("Keep Awake (Uyanık Tutma) Tanılaması")
                        .font(.headline)
                    
                    diagnosticRow(
                        title: "Sistem Assertion (NoIdleSleep)",
                        value: app.keepAwakeState.idleSleepAssertionID != 0 ? "Etkin (ID: \(app.keepAwakeState.idleSleepAssertionID))" : "Devre Dışı"
                    )
                    diagnosticRow(
                        title: "Ekran Assertion (NoDisplaySleep)",
                        value: app.keepAwakeState.displaySleepAssertionID != 0 ? "Etkin (ID: \(app.keepAwakeState.displaySleepAssertionID))" : "Devre Dışı"
                    )
                    diagnosticRow(
                        title: "Ekranı Açık Tut Ayarı",
                        value: app.keepAwakeState.featureEnabled ? "Açık" : "Kapalı"
                    )
                    diagnosticRow(
                        title: "Yalnızca Fişe Takılıyken",
                        value: app.keepAwakeState.onlyWhilePluggedIn ? "Açık" : "Kapalı"
                    )
                    diagnosticRow(
                        title: "Varsayılan Süre Modu",
                        value: app.keepAwakeState.defaultIdleTimeoutMode
                    )
                    diagnosticRow(
                        title: "Varsayılan Özel Dakika",
                        value: "\(app.keepAwakeState.defaultIdleTimeoutMinutes) dk"
                    )
                    diagnosticRow(
                        title: "Geçerli Boşta Süresi",
                        value: app.currentIdleTimeString
                    )
                    if let overrideMode = app.keepAwakeState.temporaryIdleTimeoutMode {
                        diagnosticRow(
                            title: "Geçici Süre Modu",
                            value: overrideMode
                        )
                    }
                    diagnosticRow(
                        title: "Kalan Süre",
                        value: app.remainingIdleTimeString
                    )
                    
                    diagnosticRow(
                        title: "Son Durdurma Nedeni",
                        value: app.keepAwakeState.lastStopReason
                    )
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                
                // Otomatik Parlaklık Tanılaması
                VStack(alignment: .leading, spacing: 6) {
                    Text("Otomatik Parlaklık Tanılaması")
                        .font(.headline)
                    
                    diagnosticRow(
                        title: "Ortam Işık Seviyesi",
                        value: app.currentLux.map { String(format: "%.1f lux", $0) } ?? "Bilinmiyor"
                    )
                    diagnosticRow(
                        title: "Hesaplanan Hedef Parlaklık",
                        value: app.brightnessState.autoTargetBrightnessPercent.map { "\($0)%" } ?? "Bilinmiyor"
                    )
                    diagnosticRow(
                        title: "Yumuşatılmış Hedef Parlaklık",
                        value: app.brightnessState.smoothedRequestedBrightnessPercent.map { "\($0)%" } ?? "Bilinmiyor"
                    )
                    diagnosticRow(
                        title: "Son Yazılan DDC Parlaklığı",
                        value: app.brightnessState.lastWriteAttemptPercent.map { "\($0)%" } ?? "Yazılmadı"
                    )
                    diagnosticRow(
                        title: "Son Yazma Sonrası Okunan Parlaklık",
                        value: app.brightnessState.lastWriteReadbackPercent.map { "\($0)%" } ?? "Okunmadı"
                    )
                    diagnosticRow(
                        title: "Gerçek DDC Parlaklığı",
                        value: app.brightnessState.actualDDCBrightnessPercent.map { "\($0)%" } ?? "Bilinmiyor"
                    )
                    diagnosticRow(
                        title: "DDC Okuma Durumu",
                        value: app.brightnessState.readbackStatusText
                    )
                    diagnosticRow(
                        title: "Yazma Engelleme Nedeni",
                        value: app.brightnessState.suppressionReason ?? "Yok"
                    )
                    diagnosticRow(
                        title: "Sapma Uyarısı (Mismatch)",
                        value: app.brightnessState.showMismatchWarning ? "Etkin (Fark >= 10, 2 döngüdür hedefe ulaşılamadı)" : "Normal"
                    )
                    
                    let pauseText: String = {
                        if let pausedUntil = app.brightnessState.manualOverridePausedUntil, pausedUntil > Date() {
                            let formatter = DateFormatter()
                            formatter.timeStyle = .medium
                            return "Duraklatıldı (\(formatter.string(from: pausedUntil)) tarihine kadar)"
                        }
                        return "Aktif değil"
                    }()
                    diagnosticRow(
                        title: "Manual Override Durumu",
                        value: pauseText
                    )
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                
                if let targetInfo = try? HiDPITargetDisplayResolver.resolveSamsungS60UDForDiagnostics() {
                    // Samsung Fingerprint
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Samsung Ekran Parmak İzi")
                            .font(.headline)
                        
                        let infoText = targetInfo.serialNumber.map {
                            String(format: "Üretici ID: 0x%04X | Ürün ID: 0x%04X | Seri No: 0x%08X", targetInfo.vendorID, targetInfo.productID, $0)
                        } ?? String(format: "Üretici ID: 0x%04X | Ürün ID: 0x%04X | Seri No okunamaz", targetInfo.vendorID, targetInfo.productID)
                        
                        diagnosticRow(title: "Fingerprint", value: infoText)
                        diagnosticRow(title: "Dahili Ekran", value: targetInfo.isBuiltin ? "Evet" : "Hayır")
                    }
                    .padding(10)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                    
                    // EDID Bilgileri
                    if let edid = app.currentEDIDSummary {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("EDID Özet")
                                .font(.headline)
                            
                            diagnosticRow(title: "EDID Mevcut", value: edid.edidAvailable ? "EVET" : "HAYIR")
                            diagnosticRow(title: "EDID Hash", value: edid.sha256 ?? "Bilinmiyor")
                            diagnosticRow(title: "Üretici Kodu", value: edid.manufacturerCode ?? "Bilinmiyor")
                            diagnosticRow(title: "Ürün Kodu", value: edid.productCode.map { String(format: "0x%04X", $0) } ?? "Bilinmiyor")
                            diagnosticRow(title: "Seri Numarası", value: edid.serialNumber.map { String(format: "0x%08X", $0) } ?? "Bilinmiyor")
                            diagnosticRow(title: "Ekran Adı", value: edid.edidDisplayName ?? "Bilinmiyor")
                            diagnosticRow(title: "Eşleşme Güveni", value: edid.matchConfidence.displayText)
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // CGS Modları
                    let status = app.cgsManualModeSwitcherSummary
                    let dynamic = app.cgsDynamicSelectionState
                    let overrideStatus = HiDPIDisplayOverrideManager.statusOverview()
                    let validation = HiDPIDisplayOverrideManager.validateExistingOverride()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Çözünürlük ve CGS Mod Bilgileri")
                            .font(.headline)
                        
                        diagnosticRow(title: "CGS Mevcut Mod ID", value: status?.currentModeID.map(String.init) ?? "Bilinmiyor")
                        diagnosticRow(title: "Dinamik HiDPI Aday ID", value: dynamic?.dynamicHiDPICandidate.map { String($0.modeID) } ?? "Bilinmiyor")
                        diagnosticRow(title: "Dinamik Normal Aday ID", value: dynamic?.dynamicNormalCandidate.map { String($0.modeID) } ?? "Bilinmiyor")
                        diagnosticRow(title: "Samsung Fallback Kullanımı", value: app.cgsSamsungFallbackUsed ? "EVET" : "HAYIR")
                        diagnosticRow(title: "CGS Mod Sayısı", value: dynamic.map { String($0.modeCount) } ?? (status.map { String($0.cgsModeCount) } ?? "Bilinmiyor"))
                        diagnosticRow(title: "Override SHA256 Eşleşmesi", value: overrideStatus.systemMatchesBundledReference ? "Evet" : "Hayır")
                        diagnosticRow(title: "5K Normal Kayıt Mevcut", value: validation.has5KNormal ? "Evet" : "Hayır")
                        diagnosticRow(title: "5K HiDPI Kayıt Mevcut", value: validation.has5KHiDPI ? "Evet" : "Hayır")
                        diagnosticRow(title: "Mükemmel QHD Kayıtları Tam", value: overrideStatus.perfectQHDRecordsPresent ? "Evet" : "Hayır")
                    }
                    .padding(10)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                    
                    // HDR Parlaklık
                    if let hdr = app.hdrBrightnessDiagnosticSummary {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("HDR Parlaklık Tanılaması")
                                .font(.headline)
                            
                            diagnosticRow(title: "DDC Parlaklık Mevcut", value: hdr.ddcBrightnessAvailable ? "EVET" : "HAYIR")
                            diagnosticRow(title: "HDR'da DDC Çalışması", value: hdr.ddcWorksInHDRText)
                            diagnosticRow(title: "EDR Desteği", value: hdr.edrAvailableText)
                            diagnosticRow(title: "Önerilen Yol", value: hdr.recommendedPathText)
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // DDC Sınırları
                    if let ddc = app.ddcBrightnessMaxDiagnosticSummary {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("DDC Parlaklık Maksimum Tanılaması")
                                .font(.headline)
                            
                            diagnosticRow(title: "DDC Mevcut/Maks Parlaklık", value: "\(ddc.ddcBrightnessAvailableText) / \(ddc.ddcBrightnessMaxText)")
                            diagnosticRow(title: "100'e Eşitleme Sonucu", value: ddc.setBrightness100ResultText)
                            diagnosticRow(title: "Yazma Sonrası Okuma", value: ddc.brightnessReadbackAfterSet100Text)
                            diagnosticRow(title: "DDC Mevcut/Maks Kontrast", value: "\(ddc.ddcContrastCurrentText) / \(ddc.ddcContrastMaxText)")
                            diagnosticRow(title: "MCCS Kapasiteleri", value: ddc.mccsCapabilitiesAvailableText)
                            diagnosticRow(title: "Potansiyel Sınırlayıcı", value: ddc.possibleBrightnessLimiter.displayText)
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                    }

                    // DDC Raw Brightness Probe
                    if let probe = app.ddcRawBrightnessProbeSummary {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("DDC Raw Parlaklık Probe")
                                .font(.headline)

                            diagnosticRow(title: "Raw Önce", value: probe.rawCurrentBeforeText)
                            diagnosticRow(title: "Raw Max", value: probe.rawMaxText)
                            diagnosticRow(title: "İstenen Raw Max", value: probe.requestedRawMaxText)
                            diagnosticRow(title: "Yazma Sonucu", value: probe.writeResultText)
                            diagnosticRow(title: "Raw Sonra", value: probe.rawAfterText)
                            diagnosticRow(title: "Normalize Sonra", value: probe.normalizedAfterPercentText)
                            diagnosticRow(title: "Matched Max", value: probe.matchedMaxText)
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Butonlar
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tanılama İşlemlerini Çalıştır")
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            Button("EDID Tanılaması") { app.readEDIDDiagnostic() }
                            Button("HDR Tanılaması") { app.readHDRBrightnessDiagnostic() }
                            Button("DDC Tanılaması") { app.readDDCBrightnessMaxDiagnostic() }
                            Button("Run DDC Raw Brightness Probe") { app.readDDCRawBrightnessProbeDiagnostic() }
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Parlaklık Haritalama Tanılaması") { app.readBrightnessMappingDiagnostic() }
                            .buttonStyle(.bordered)
                    }
                    .padding(.top, 4)
                    
                } else {
                    Text("Samsung S60UD veya desteklenen bir Samsung ekran bulunamadı. Tanılama aracı pasif.")
                        .foregroundStyle(.secondary)
                        .font(.body)
                }
            }
            .padding(12)
        }
        .navigationTitle("Tanılama")
    }
    
    private func diagnosticRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 200, alignment: .leading)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            Spacer()
        }
    }
}
