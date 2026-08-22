import Foundation
import IOKit
import IOKit.hid

let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(0))
IOHIDManagerSetDeviceMatching(manager, nil)
let openResult = IOHIDManagerOpen(manager, IOOptionBits(0))
print("openResult=\(openResult)")

if let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> {
    print("devices=\(devices.count)")
    for device in devices {
        let product = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "unknown"
        let vendor = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString)
        let usagePage = IOHIDDeviceGetProperty(device, kIOHIDDeviceUsagePageKey as CFString)
        let usage = IOHIDDeviceGetProperty(device, kIOHIDDeviceUsageKey as CFString)
        print("product=\(product) vendor=\(String(describing: vendor)) usagePage=\(String(describing: usagePage)) usage=\(String(describing: usage))")

        if let elements = IOHIDDeviceCopyMatchingElements(device, nil, 0) as? [IOHIDElement] {
            for element in elements {
                let page = IOHIDElementGetUsagePage(element)
                let u = IOHIDElementGetUsage(element)
                if page == kHIDPage_Sensor || u == kHIDUsage_Snsr_Light_AmbientLight {
                    print("  element page=\(page) usage=\(u)")
                }
            }
        }
    }
}
