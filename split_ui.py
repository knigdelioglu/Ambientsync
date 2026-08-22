import re
import os

def read_file(path):
    with open(path, 'r') as f:
        return f.read()

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content)

content = read_file('Sources/AmbientSync/UI/PreferencesView.swift')

pattern = re.compile(r'struct QuickActionsView: View\b.*?{', re.MULTILINE)
match = pattern.search(content)

if match:
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
    body = content[line_start:end_index]
    
    # Remove from original
    content = content.replace(body, "")
    write_file('Sources/AmbientSync/UI/PreferencesView.swift', content)
    
    # Write to new file
    write_file('Sources/AmbientSync/UI/QuickActionsView.swift', "import SwiftUI\n\n" + body + "\n")
