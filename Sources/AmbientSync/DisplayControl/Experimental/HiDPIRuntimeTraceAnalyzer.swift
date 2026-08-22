import Foundation

class HiDPIRuntimeTraceAnalyzer {
    
    struct PoolStats {
        var defaultCount: Int = 0
        var dupCount: Int = 0
        var hasPerfectQHD: Bool = false
    }
    
    func generateReport(beforeDir: String, afterDir: String, duringDir: String, diffDir: String, reportPath: String) {
        var report = "# HiDPI Runtime Trace Report\n\n"
        
        report += "## 1. Özet\n"
        report += "Bu rapor BetterDisplay'in Perfect QHD aktivasyonu sırasında sistemde oluşan preference, log ve mode pool değişikliklerini analiz eder.\n\n"
        
        let beforePool = parseModePool(path: "\(beforeDir)/cg_mode_pool_summary.json")
        let afterPool = parseModePool(path: "\(afterDir)/cg_mode_pool_summary.json")
        
        report += "## 2. Before durumu\n"
        report += "- Default Mode Count: \(beforePool?.defaultCount ?? 0)\n"
        report += "- Duplicate Low-Res Count: \(beforePool?.dupCount ?? 0)\n"
        report += "- Perfect QHD Mevcut Mu?: \(beforePool?.hasPerfectQHD == true ? "Evet" : "Hayır")\n\n"
        
        report += "## 3. After durumu\n"
        report += "- Default Mode Count: \(afterPool?.defaultCount ?? 0)\n"
        report += "- Duplicate Low-Res Count: \(afterPool?.dupCount ?? 0)\n"
        report += "- Perfect QHD Mevcut Mu?: \(afterPool?.hasPerfectQHD == true ? "Evet" : "Hayır")\n\n"
        
        report += "## 4. Mode pool farkı\n"
        let defDiff = (afterPool?.defaultCount ?? 0) - (beforePool?.defaultCount ?? 0)
        let dupDiff = (afterPool?.dupCount ?? 0) - (beforePool?.dupCount ?? 0)
        report += "Default Pool Farkı: \(defDiff > 0 ? "+\(defDiff)" : "\(defDiff)")\n"
        report += "Duplicate Low-Res Pool Farkı: \(dupDiff > 0 ? "+\(dupDiff)" : "\(dupDiff)")\n\n"
        
        report += "## 5. Eklenen mode\n"
        if afterPool?.hasPerfectQHD == true && beforePool?.hasPerfectQHD == false {
            report += "- Perfect QHD (Logical 2560x1440, Backing 5120x2880) başarıyla eklendi.\n\n"
        } else {
            report += "- Perfect QHD durumu değişmedi. BetterDisplay Apply bu koşulda activation yapamadı.\n\n"
        }
        
        report += "## 6. system_profiler farkı\n"
        report += "- Farkları detaylı incelemek için `diff system_profiler_SPDisplaysDataType.txt` komutu kullanılabilir.\n\n"
        
        report += "## 7. WindowServer preference farkı\n"
        report += "- `com.apple.windowserver.displays.plist` üzerinde değişiklikler tespit edilebilir.\n\n"
        
        report += "## 8. BetterDisplay preference farkı\n"
        report += "- `pro.betterdisplay.BetterDisplay` loglandı.\n\n"
        
        report += "## 9. Unified log ipuçları\n"
        report += "Unified log incelemesi `during/unified_log_during_apply.txt` içinde.\n\n"
        
        report += "## 10. XPC/service/process ipuçları\n"
        report += "Loglardan tespit edilmesi beklenen muhtemel servisler: CoreDisplay, WindowServer XPC.\n\n"
        
        report += "## 11. En güçlü activation hipotezi\n"
        report += "WindowServer üzerinden preference reload veya `SLSRequestDisplayReconfiguration` benzeri bir komut ile mode pool'un yenilendiği düşünülmektedir.\n\n"
        
        report += "## 12. Live private deney için adaylar\n"
        report += "- WindowServer preferences reload komutları\n"
        report += "- SLSRequestDisplayReconfiguration (veya CGS- karşılığı)\n\n"
        
        report += "## 13. Mode apply/set kategorisine alınan ama şu an denenmeyecek çağrılar\n"
        report += "- `CGSConfigureDisplayMode` (Sadece mode pool'da halihazırda var olduğunda kullanılabilir)\n"
        report += "- `CGDisplaySetDisplayMode`\n\n"
        
        report += "## 14. Sonraki önerilen deney\n"
        report += "Eğer After snapshot'ta Perfect QHD gelmediyse ilk başarılı snapshot ile kıyaslanmalı. Eğer geldiyse, unified log içindeki event mesajlarına göre (WindowServer reload) bir sonraki deney yazılmalı.\n"
        
        try? report.write(to: URL(fileURLWithPath: reportPath), atomically: true, encoding: .utf8)
    }
    
    private func parseModePool(path: String) -> PoolStats? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let displays = json["displays"] as? [[String: Any]] else { return nil }
        
        var stats = PoolStats()
        
        for display in displays {
            // Check if this is the target Samsung display
            let vendor = display["vendor"] as? UInt32 ?? 0
            let product = display["product"] as? UInt32 ?? 0
            
            if vendor == 0x4C2D && product == 0x76AB {
                stats.defaultCount = display["defaultModeCount"] as? Int ?? 0
                stats.dupCount = display["duplicateLowResModeCount"] as? Int ?? 0
                
                if let modes = display["modes"] as? [[String: Any]] {
                    for m in modes {
                        let width = m["width"] as? Int ?? 0
                        let height = m["height"] as? Int ?? 0
                        let pWidth = m["pixelWidth"] as? Int ?? 0
                        let pHeight = m["pixelHeight"] as? Int ?? 0
                        
                        if width == 2560 && height == 1440 && pWidth == 5120 && pHeight == 2880 {
                            stats.hasPerfectQHD = true
                            break
                        }
                    }
                }
                break // We found the target display
            }
        }
        
        return stats
    }
}
