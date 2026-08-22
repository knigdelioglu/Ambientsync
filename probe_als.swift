import Foundation
import Darwin

private let ambientLightSensorEvent: Int64 = 12
private let ambientLightFieldBase: Int32 = Int32(ambientLightSensorEvent << 16)

typealias ALCALSCopyALSServiceClientFn = @convention(c) () -> Unmanaged<AnyObject>?
typealias IOHIDServiceClientCopyEventFn = @convention(c) (CFTypeRef, Int64, Int32, Int64) -> Unmanaged<AnyObject>?
typealias IOHIDEventGetFloatValueFn = @convention(c) (CFTypeRef, Int32) -> Double

func symbol<T>(_ name: String, as type: T.Type) -> T? {
    let bezelHandle = dlopen("/System/Library/PrivateFrameworks/BezelServices.framework/BezelServices", RTLD_LAZY)
    let iokitHandle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_LAZY)
    for handle in [bezelHandle, iokitHandle, nil] {
        if let handle, let raw = dlsym(handle, name) {
            return unsafeBitCast(raw, to: T.self)
        }
    }
    return nil
}

guard
    let copyClient: ALCALSCopyALSServiceClientFn = symbol("ALCALSCopyALSServiceClient", as: ALCALSCopyALSServiceClientFn.self),
    let copyEvent: IOHIDServiceClientCopyEventFn = symbol("IOHIDServiceClientCopyEvent", as: IOHIDServiceClientCopyEventFn.self),
    let readFloatValue: IOHIDEventGetFloatValueFn = symbol("IOHIDEventGetFloatValue", as: IOHIDEventGetFloatValueFn.self),
    let client = copyClient()?.takeRetainedValue() as? CFTypeRef,
    let event = copyEvent(client, ambientLightSensorEvent, 0, 0)?.takeRetainedValue() as? CFTypeRef
else {
    print("failed")
    exit(1)
}

let lux = readFloatValue(event, ambientLightFieldBase)
print(lux)
