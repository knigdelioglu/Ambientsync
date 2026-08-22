import Foundation
import MachO

class PrivateDisplaySymbolResolver {
    static let shared = PrivateDisplaySymbolResolver()
    private init() {}
    func resolveSymbol(name: String) -> UnsafeMutableRawPointer? {
        let handle = UnsafeMutableRawPointer(bitPattern: -2)
        return dlsym(handle, name)
    }
    func getLoadedDisplayImages() -> [String] {
        var relevantImages: [String] = []
        let count = _dyld_image_count()
        for i in 0..<count {
            if let cName = _dyld_get_image_name(i) {
                let name = String(cString: cName)
                if name.contains("SkyLight") || name.contains("CoreDisplay") || 
                   name.contains("DisplayServices") || name.contains("CoreGraphics") {
                    relevantImages.append(name)
                }
            }
        }
        return relevantImages
    }
    func runDiscovery() -> String {
        var report = "# Private Symbol Discovery Report (Global Namespace)\n\n"
        let images = getLoadedDisplayImages()
        report += "## Loaded Relevant Dyld Images\n"
        for img in images { report += "- \(img)\n" }
        report += "\n"
        let candidateSymbols = [
            "SLSRequestDisplayReconfiguration",
            "CGSRequestDisplayReconfiguration",
            "SLSDisplayModeRefreshList",
            "CoreDisplay_DisplayModeRefreshList",
            "CGSReloadDisplayConfiguration",
            "CGSDisplayConfigReload",
            "CGSConfigureDisplayMode",
            "CGDisplaySetDisplayMode",
            "CoreDisplay_DisplayCreateInfoDictionary",
            "CGSCopyDisplayInfoDictionary"
        ]
        report += "## Symbol Resolution via RTLD_DEFAULT\n"
        for symbol in candidateSymbols {
            if resolveSymbol(name: symbol) != nil { report += "- ✅ \(symbol)\n" }
            else { report += "- ❌ \(symbol)\n" }
        }
        return report
    }
}

let report = PrivateDisplaySymbolResolver.shared.runDiscovery()
let url = URL(fileURLWithPath: "docs/generated/private_activation/symbol_scan_report.md")
try? report.write(to: url, atomically: true, encoding: .utf8)
print("Discovery complete. Report saved.")
