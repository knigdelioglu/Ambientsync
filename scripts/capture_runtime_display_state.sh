#!/bin/bash
OUT_DIR="$1"
if [ -z "$OUT_DIR" ]; then
    echo "Usage: $0 <output_directory>"
    exit 1
fi
mkdir -p "$OUT_DIR"

echo "Capturing state into $OUT_DIR..."

date > "$OUT_DIR/timestamp.txt"
system_profiler SPDisplaysDataType > "$OUT_DIR/system_profiler_SPDisplaysDataType.txt" 2>/dev/null || true
system_profiler -json SPDisplaysDataType > "$OUT_DIR/system_profiler_SPDisplaysDataType.json" 2>/dev/null || true

defaults read /Library/Preferences/com.apple.windowserver.displays.plist > "$OUT_DIR/windowserver_preferences_dump.txt" 2>/dev/null || true
for f in ~/Library/Preferences/ByHost/com.apple.windowserver.displays.*.plist; do
    defaults read "$f" >> "$OUT_DIR/user_windowserver_preferences_dump.txt" 2>/dev/null || true
done

defaults read pro.betterdisplay.BetterDisplay > "$OUT_DIR/betterdisplay_preferences_dump.txt" 2>/dev/null || true

shasum /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-4c2d/DisplayProductID-76ab > "$OUT_DIR/override_file_sha256.txt" 2>/dev/null || true
plutil -p /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-4c2d/DisplayProductID-76ab > "$OUT_DIR/override_plist_dump.txt" 2>/dev/null || true

launchctl list | grep -i display > "$OUT_DIR/launchctl_display_services.txt" 2>/dev/null || true
ps aux | grep -i display > "$OUT_DIR/ps_display_processes.txt" 2>/dev/null || true

lsof -c BetterDisplay > "$OUT_DIR/lsof_betterdisplay.txt" 2>>"$OUT_DIR/lsof_betterdisplay_error.txt" || true
lsof -c WindowServer > "$OUT_DIR/lsof_windowserver.txt" 2>>"$OUT_DIR/lsof_windowserver_error.txt" || true

# Dump CoreGraphics state using a mini swift script
cat << 'EOF' > /tmp/dump_cg.swift
import Foundation
import CoreGraphics

let outDir = CommandLine.arguments[1]

var displayCount: UInt32 = 0
var displays = [CGDirectDisplayID](repeating: 0, count: 10)
CGGetActiveDisplayList(10, &displays, &displayCount)

var summary = [String: Any]()
var modesArray = [[String: Any]]()

for i in 0..<Int(displayCount) {
    let d = displays[i]
    var dInfo = [String: Any]()
    dInfo["displayID"] = d
    dInfo["vendor"] = CGDisplayVendorNumber(d)
    dInfo["product"] = CGDisplayModelNumber(d)
    dInfo["serial"] = CGDisplaySerialNumber(d)
    
    // Default modes
    if let modes = CGDisplayCopyAllDisplayModes(d, nil) as? [CGDisplayMode] {
        dInfo["defaultModeCount"] = modes.count
    }
    
    // Duplicate low res modes
    let options = [kCGDisplayShowDuplicateLowResolutionModes: true] as CFDictionary
    if let modesLowRes = CGDisplayCopyAllDisplayModes(d, options) as? [CGDisplayMode] {
        dInfo["duplicateLowResModeCount"] = modesLowRes.count
        var mList = [[String: Any]]()
        for m in modesLowRes {
            var mDict = [String: Any]()
            mDict["width"] = m.width
            mDict["height"] = m.height
            mDict["pixelWidth"] = m.pixelWidth
            mDict["pixelHeight"] = m.pixelHeight
            mDict["refreshRate"] = m.refreshRate
            mDict["ioDisplayModeID"] = m.ioDisplayModeID
            mList.append(mDict)
        }
        dInfo["modes"] = mList
    }
    modesArray.append(dInfo)
}

summary["displays"] = modesArray

if let data = try? JSONSerialization.data(withJSONObject: summary, options: .prettyPrinted) {
    let url = URL(fileURLWithPath: outDir).appendingPathComponent("cg_mode_pool_summary.json")
    try? data.write(to: url)
}
EOF

swift /tmp/dump_cg.swift "$OUT_DIR"
echo "Snapshot complete."
