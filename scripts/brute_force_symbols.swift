import Foundation

func listFoundSymbols() {
    let frameworks = [
        "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
        "/System/Library/PrivateFrameworks/CoreDisplay.framework/CoreDisplay"
    ]
    
    let patterns = [
        "Reconfigure", "Reload", "Update", "Refresh", "Scale", "User", "Config", "Mode", "HiDPI", "LowRes"
    ]
    
    // Common known private symbols from various sources
    let knownPrivate = [
        "CGSRequestDisplayReconfiguration",
        "SLSRequestDisplayReconfiguration",
        "CGSDisplayReconfigure",
        "SLSDisplayReconfigure",
        "CGSSetDisplayUserScale",
        "SLSSetDisplayUserScale",
        "CGSRegisterDisplayModeConfiguration",
        "SLSRegisterDisplayModeConfiguration",
        "CGSDisplayModeRefreshList",
        "SLSDisplayModeRefreshList",
        "CoreDisplay_DisplayModeRefreshList",
        "CGSSetDisplayScale",
        "SLSSetDisplayScale",
        "CGSDisplaySetScale",
        "SLSDisplaySetScale"
    ]
    
    for fw in frameworks {
        print("--- Checking \(fw) ---")
        guard let handle = dlopen(fw, RTLD_NOW) else { continue }
        for s in knownPrivate {
            if dlsym(handle, s) != nil {
                print("✅ Found: \(s)")
            }
        }
    }
}

listFoundSymbols()
