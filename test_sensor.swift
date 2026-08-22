import Foundation
import IOKit
import IOKit.hid

private let sensorCallback: IOHIDValueCallback = { context, result, sender, value in
    guard result == kIOReturnSuccess else { return }
    let element = IOHIDValueGetElement(value)
    let page = IOHIDElementGetUsagePage(element)
    let usage = IOHIDElementGetUsage(element)
    let integerValue = IOHIDValueGetIntegerValue(value)
    let scaledValue = IOHIDValueGetScaledValue(value, IOHIDValueScaleType(kIOHIDValueScaleTypeCalibrated))
    print("value page=\(page) usage=\(usage) int=\(integerValue) scaled=\(scaledValue)")
    fflush(stdout)
}

let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(0))
let matching: [String: Any] = [
    kIOHIDDeviceUsagePageKey: kHIDPage_Sensor,
    kIOHIDDeviceUsageKey: kHIDUsage_Snsr_Light_AmbientLight,
]

IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
IOHIDManagerRegisterInputValueCallback(manager, sensorCallback, nil)
IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
print("openResult=\(openResult)")

let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> ?? []
print("devices=\(devices.count)")
for device in devices {
    let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "unknown"
    print("device=\(name)")
}

CFRunLoopRun()
