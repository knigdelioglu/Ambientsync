import re
import os
import sys

def split_swift_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # We will match top level definitions
    # protocol, struct, class, enum, extension
    pattern = re.compile(r'^(?:@\w+\s+)?(?:public\s+|private\s+|internal\s+|fileprivate\s+|final\s+)*(class|struct|enum|protocol|extension)\s+(\w+).*?{', re.MULTILINE)
    
    parts = {}
    last_end = 0
    
    for match in pattern.finditer(content):
        # Find the matching closing brace
        start_index = match.end() - 1
        brace_count = 1
        end_index = start_index + 1
        while brace_count > 0 and end_index < len(content):
            if content[end_index] == '{':
                brace_count += 1
            elif content[end_index] == '}':
                brace_count -= 1
            end_index += 1
            
        type_name = match.group(2)
        # Capture from the beginning of the line
        line_start = content.rfind('\n', 0, match.start()) + 1
        # Include attributes preceding it, e.g. @MainActor
        prev_line_start = content.rfind('\n', 0, max(0, line_start - 1)) + 1
        if prev_line_start >= 0 and content[prev_line_start:line_start].strip().startswith('@'):
            line_start = prev_line_start
            
        body = content[line_start:end_index]
        parts[type_name] = body
        
    return parts

parts = split_swift_file('Sources/AmbientSync/main.swift')
for k, v in parts.items():
    print(f"{k}: {len(v)} chars")

