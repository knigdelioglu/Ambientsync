import Foundation

func listAllSymbols(path: String, pattern: String) {
    guard let handle = dlopen(path, RTLD_NOW) else { return }
    
    // We can't easily iterate dlsym without a symbol table. 
    // But we can try a list of suspected symbols.
    
    let suspects = [
        "CGSRequestDisplayReconfiguration",
        "SLSRequestDisplayReconfiguration",
        "CGSDisplayReconfigure",
        "SLSDisplayReconfigure",
        "CGSSetDisplayUserScale",
        "SLSSetDisplayUserScale",
        "CGSDisplaySetUserScale",
        "SLSDisplaySetUserScale",
        "CGSReloadDisplayConfiguration",
        "SLSReloadDisplayConfiguration",
        "CGSDisplayConfigReload",
        "SLSDisplayConfigReload",
        "CGSUpdateDisplayConfiguration",
        "SLSUpdateDisplayConfiguration"
    ]
    
    print("Checking suspects in \(path):")
    for s in suspects {
        if dlsym(handle, s) != nil {
            print("✅ \(s)")
        }
    }
}

let skylightPath = "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight"
listAllSymbols(path: skylightPath, pattern: "Display")
