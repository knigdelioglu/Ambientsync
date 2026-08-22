import re
import os

def read_file(path):
    with open(path, 'r') as f:
        return f.read()

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content)

main_content = read_file('Sources/AmbientSync/main.swift')
models_content = read_file('Sources/AmbientSync/Preferences/AmbientSyncModels.swift')

imports = "import AppKit\nimport Foundation\nimport IOKit\nimport IOKit.hid\nimport IOKit.ps\nimport IOKit.pwr_mgt\nimport Darwin\nimport SwiftUI\n\n"

# Helper to find top-level entity
def extract_entity(content, name):
    pattern = re.compile(r'^(?:@\w+\s+)?(?:public\s+|private\s+|internal\s+|fileprivate\s+|final\s+)*(class|struct|enum|protocol|extension)\s+' + name + r'\b.*?{', re.MULTILINE)
    match = pattern.search(content)
    if not match:
        return ""
    
    start_index = match.end() - 1
    brace_count = 1
    end_index = start_index + 1
    while brace_count > 0 and end_index < len(content):
        if content[end_index] == '{':
            brace_count += 1
        elif content[end_index] == '}':
            brace_count -= 1
        end_index += 1
        
    line_start = content.rfind('\n', 0, match.start()) + 1
    prev_line_start = content.rfind('\n', 0, max(0, line_start - 1)) + 1
    if prev_line_start >= 0 and content[prev_line_start:line_start].strip().startswith('@'):
        line_start = prev_line_start
        
    return content[line_start:end_index]

def remove_entity(content, entity_body):
    if not entity_body: return content
    return content.replace(entity_body, "")

# Mappings
entities = {
    'AmbientSensorConstants': 'Sensors/PrivateALSSensorReader.swift',
    'PrivateSymbols': 'Sensors/PrivateALSSensorReader.swift',
    'AmbientLightReader': 'Sensors/PrivateALSSensorReader.swift',
    'M1DDCCommandResult': 'DisplayControl/M1DDCDisplayController.swift',
    'M1DDCWriter': 'DisplayControl/M1DDCDisplayController.swift',
    'BetterDisplayController': 'DisplayControl/BetterDisplayController.swift',
    'KeepAwakeScope': 'System/KeepAwakeController.swift',
    'KeepAwakeController': 'System/KeepAwakeController.swift',
    'PowerSourceState': 'System/PowerSourceController.swift',
    'PowerSourceController': 'System/PowerSourceController.swift',
    'InternalDisplayBrightnessController': 'DisplayControl/InternalDisplayBrightnessController.swift',
    'StatusBarView': 'App/StatusBarController.swift',
    'PowerStatusMenuView': 'App/StatusBarController.swift',
    'RouteBannerController': 'UI/RouteBannerController.swift',
    'QuickActionsPopoverController': 'App/QuickActionsPopoverController.swift',
    'MonitorVolumeKeyAction': 'System/MonitorVolumeKeyRouter.swift',
    'MonitorVolumeKeyRouter': 'System/MonitorVolumeKeyRouter.swift',
    'AppState': 'App/AppDelegate.swift'
}

typealiases = """
private typealias ALCALSCopyALSServiceClientFn = @convention(c) () -> Unmanaged<AnyObject>?
private typealias IOHIDServiceClientCopyEventFn = @convention(c) (CFTypeRef, Int64, Int32, Int64) -> Unmanaged<AnyObject>?
private typealias IOHIDEventGetFloatValueFn = @convention(c) (CFTypeRef, Int32) -> Double
private typealias IODisplaySetFloatParameterFn = @convention(c) (io_service_t, IOOptionBits, CFString, Float) -> IOReturn
private typealias CGDisplayIOServicePortFn = @convention(c) (CGDirectDisplayID) -> io_service_t
"""

file_contents = {}

for name, filepath in entities.items():
    body = extract_entity(main_content, name)
    main_content = remove_entity(main_content, body)
    
    # If the entity requires typealiases
    prefix = ""
    if name in ['AmbientLightReader']:
        prefix = typealiases
    if name in ['InternalDisplayBrightnessController']:
        prefix = "private typealias IODisplaySetFloatParameterFn = @convention(c) (io_service_t, IOOptionBits, CFString, Float) -> IOReturn\nprivate typealias CGDisplayIOServicePortFn = @convention(c) (CGDirectDisplayID) -> io_service_t\n"

    if filepath not in file_contents:
        file_contents[filepath] = imports + prefix + body + "\n"
    else:
        file_contents[filepath] += "\n" + prefix + body + "\n"

# Cleanup main_content (remove empty lines, typealiases, systemDefinedCGEventType)
main_content = re.sub(r'private typealias.*?\n', '', main_content)
main_content = re.sub(r'private let systemDefinedCGEventType.*?\n', '', main_content)
main_content = re.sub(r'\n{3,}', '\n\n', main_content)

for filepath, content in file_contents.items():
    write_file('Sources/AmbientSync/' + filepath, content)

# Write back main.swift
write_file('Sources/AmbientSync/main.swift', main_content)

# Now, do BrightnessEngine extraction from AmbientSyncModels.swift
models_entities = {
    'LuxFilter': 'BrightnessEngine/LuxFilter.swift',
    'BrightnessCurve': 'BrightnessEngine/BrightnessCurve.swift'
}

for name, filepath in models_entities.items():
    body = extract_entity(models_content, name)
    if body:
        models_content = remove_entity(models_content, body)
        write_file('Sources/AmbientSync/' + filepath, imports + body + "\n")

# Re-write models content
write_file('Sources/AmbientSync/Preferences/AmbientSyncModels.swift', models_content)
