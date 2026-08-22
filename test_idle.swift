import Foundation
import CoreGraphics

let idle = CGEventSource.secondsSinceLastEventType(CGEventSourceStateID.hidSystemState, eventType: CGEventType(rawValue: ~0)!)
print("Idle seconds: \(idle)")
