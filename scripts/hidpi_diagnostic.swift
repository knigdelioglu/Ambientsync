import Foundation
import AppKit
import CoreGraphics

func getDisplayName(for displayID: CGDirectDisplayID) -> String {
    let screen = NSScreen.screens.first { screen in
        let key = NSDeviceDescriptionKey("ESDDisplayDeviceID")
        if let num = screen.deviceDescription[key] as? NSNumber {
            return num.uint32Value == displayID
        }
        return false
    }
    return screen?.localizedName ?? "Bilinmeyen Ekran"
}

struct ScaleResolution {
    let width: Int32
    let height: Int32
    let flags: Int32?
    let hex: String
}

func parseBase64Resolution(_ base64Str: String) -> ScaleResolution? {
    guard let data = Data(base64Encoded: base64Str.trimmingCharacters(in: .whitespacesAndNewlines)) else {
        return nil
    }
    
    let hex = data.map { String(format: "%02hhX", $0) }.joined()
    
    guard data.count >= 8 else { return nil }
    
    var w: Int32 = 0
    var h: Int32 = 0
    (data.subdata(in: 0..<4) as NSData).getBytes(&w, length: 4)
    (data.subdata(in: 4..<8) as NSData).getBytes(&h, length: 4)
    
    // Big-endian'ı Mac'in host endianness'ına çevirelim
    w = Int32(bigEndian: w)
    h = Int32(bigEndian: h)
    
    var flags: Int32? = nil
    if data.count >= 12 {
        var f: Int32 = 0
        (data.subdata(in: 8..<12) as NSData).getBytes(&f, length: 4)
        flags = Int32(bigEndian: f)
    }
    
    return ScaleResolution(width: w, height: h, flags: flags, hex: hex)
}

func analyzeOverridePlist(vendorId: UInt32, productId: UInt32) {
    let vendorHex = String(format: "%02x", vendorId)
    let productHex = String(format: "%02x", productId)
    let path = "/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-\(vendorHex)/DisplayProductID-\(productHex)"
    
    print("\n=== SYSTEM OVERRIDE DOSYASI ANALİZİ ===")
    print("Yol: \(path)")
    
    guard FileManager.default.fileExists(atPath: path) else {
        print("Override plist dosyası bulunamadı.")
        return
    }
    
    guard let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
        print("Plist okunamadı veya parse edilemedi.")
        return
    }
    
    if let scaleResolutions = dict["scale-resolutions"] as? [Data] {
        print("Tanımlı scale-resolutions sayısı: \(scaleResolutions.count)")
        for (index, data) in scaleResolutions.enumerated() {
            let base64Str = data.base64EncodedString()
            if let res = parseBase64Resolution(base64Str) {
                let flagsText = res.flags != nil ? String(format: "0x%08X", res.flags!) : "Yok"
                print(String(format: "  [%02d] Çözünürlük: %dx%d | Flag: %@ | Hex: %@ | Base64: %@", index + 1, res.width, res.height, flagsText, res.hex, base64Str))
            }
        }
    } else {
        print("scale-resolutions anahtarı bulunamadı.")
    }
    
    if let ppmm = dict["target-default-ppmm"] {
        print("target-default-ppmm: \(ppmm)")
    }
}

func printDisplayDiagnostics() {
    let maxDisplays: UInt32 = 16
    var activeDisplays = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
    var displayCount: UInt32 = 0
    
    guard CGGetActiveDisplayList(maxDisplays, &activeDisplays, &displayCount) == .success else {
        print("Aktif ekran listesi alınamadı.")
        return
    }
    
    print("=== AKTİF EKRANLAR (\(displayCount) adet) ===")
    
    for i in 0..<Int(displayCount) {
        let displayID = activeDisplays[i]
        let vendorId = CGDisplayVendorNumber(displayID)
        let productId = CGDisplayModelNumber(displayID)
        let serial = CGDisplaySerialNumber(displayID)
        let isBuiltin = CGDisplayIsBuiltin(displayID) != 0
        let isOnline = CGDisplayIsOnline(displayID) != 0
        let isActive = CGDisplayIsActive(displayID) != 0
        let name = getDisplayName(for: displayID)
        
        let vendorHex = String(format: "0x%X", vendorId)
        let productHex = String(format: "0x%X", productId)
        let serialHex = String(format: "0x%X", serial)
        
        print("\n--------------------------------------------")
        print("Ekran #\(i + 1): \(name)")
        print("  - DisplayID: \(displayID)")
        print("  - Vendor ID: \(vendorHex) (\(vendorId))")
        print("  - Product ID: \(productHex) (\(productId))")
        print("  - Serial: \(serialHex) (\(serial))")
        print("  - Dahili Ekran mı: \(isBuiltin)")
        
        // Aktif Mod
        if let currentMode = CGDisplayCopyDisplayMode(displayID) {
            print("  - Aktif Mod:")
            print("    * Mantıksal Çözünürlük: \(currentMode.width)x\(currentMode.height)")
            print("    * Piksel Çözünürlüğü: \(currentMode.pixelWidth)x\(currentMode.pixelHeight)")
            print("    * Yenileme Hızı: \(currentMode.refreshRate) Hz")
            let isHiDPI = currentMode.pixelWidth > currentMode.width
            print("    * HiDPI: \(isHiDPI)")
        }
        
        // Eğer harici ekransa plist analizi yap
        if !isBuiltin {
            analyzeOverridePlist(vendorId: vendorId, productId: productId)
        }
    }
}

printDisplayDiagnostics()
