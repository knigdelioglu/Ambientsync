import Foundation
import CoreGraphics

class PrivateDisplaySymbolResolver {
    static let shared = PrivateDisplaySymbolResolver()
    
    private var frameworkHandles: [String: UnsafeMutableRawPointer] = [:]
    
    private let skylightPath = "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight"
    private let coreDisplayPath = "/System/Library/PrivateFrameworks/CoreDisplay.framework/CoreDisplay"
    private let displayServicesPath = "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices"
    private let coreGraphicsPath = "/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics"
    
    private init() {}
    
    private func loadFramework(path: String) -> UnsafeMutableRawPointer? {
        if let handle = frameworkHandles[path] {
            return handle
        }
        
        guard let handle = dlopen(path, RTLD_NOW) else {
            return nil
        }
        
        frameworkHandles[path] = handle
        return handle
    }
    
    func resolveSymbol(name: String, inFramework path: String) -> UnsafeMutableRawPointer? {
        guard let handle = loadFramework(path: path) else { return nil }
        return dlsym(handle, name)
    }
    
    func runDiscovery() -> String {
        var report = "# Private Symbol Discovery Report\n\n"
        
        let candidateSymbols = [
            "SLSRequestDisplayReconfiguration",
            "CGSRequestDisplayReconfiguration",
            "CGSRegisterDisplayModeConfiguration",
            "SLSSetDisplayUserScale",
            "CGSSetDisplayUserScale",
            "CoreDisplay_DisplayModeRefreshList",
            "CoreDisplay_DisplayCreateInfoDictionary",
            "SLSGetDisplayModeList",
            "CGSGetDisplayModeList",
            "CGSCopyDisplayInfoDictionary",
            "CGSConfigureDisplayMode",
            "CGDisplaySetDisplayMode",
            "SLSDisplaySetUserScale"
        ]
        
        let frameworks = [
            ("SkyLight", skylightPath),
            ("CoreDisplay", coreDisplayPath),
            ("DisplayServices", displayServicesPath),
            ("CoreGraphics", coreGraphicsPath)
        ]
        
        for (frameworkName, path) in frameworks {
            report += "## Framework: \(frameworkName)\n"
            var found = 0
            for symbol in candidateSymbols {
                if resolveSymbol(name: symbol, inFramework: path) != nil {
                    report += "- ✅ \(symbol)\n"
                    found += 1
                }
            }
            if found == 0 {
                report += "- No candidate symbols found.\n"
            }
            report += "\n"
        }
        
        return report
    }
}

let report = PrivateDisplaySymbolResolver.shared.runDiscovery()
let url = URL(fileURLWithPath: "docs/generated/private_activation/symbol_scan_report.md")
do {
    try report.write(to: url, atomically: true, encoding: .utf8)
    print("Report successfully saved to \(url.path)")
} catch {
    print("Failed to save report: \(error)")
}
