#!/bin/bash

# Ensure output directory exists
mkdir -p docs/generated/private_symbols

# Framework paths
SKYLIGHT="/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight"
COREDISPLAY="/System/Library/PrivateFrameworks/CoreDisplay.framework/CoreDisplay"
DISPLAYSERVICES="/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices"
COREGRAPHICS="/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics"

# Keywords for grep (case insensitive)
KEYWORDS="Display|Mode|Modes|Reconfigure|Reconfiguration|Refresh|Resolution|Scale|HiDPI|LowResolution|UserScale|Override|Configuration|CoreDisplay|SLS|CGS|DisplayServices"

function scan_framework() {
    local framework_path=$1
    local output_file=$2
    local name=$(basename "$framework_path")

    echo "Scanning $name..."
    if [ ! -f "$framework_path" ]; then
        echo "$name not found at $framework_path" > "$output_file"
        return
    fi

    echo "--- nm export symbols ---" > "$output_file"
    nm -gU "$framework_path" 2>/dev/null | grep -iE "$KEYWORDS" >> "$output_file"

    echo -e "\n--- strings output (filtered) ---" >> "$output_file"
    strings "$framework_path" 2>/dev/null | grep -iE "$KEYWORDS" | grep -v ' ' | sort | uniq >> "$output_file"
}

scan_framework "$SKYLIGHT" "docs/generated/private_symbols/skylight_symbols.txt"
scan_framework "$COREDISPLAY" "docs/generated/private_symbols/coredisplay_symbols.txt"
scan_framework "$DISPLAYSERVICES" "docs/generated/private_symbols/displayservices_symbols.txt"
scan_framework "$COREGRAPHICS" "docs/generated/private_symbols/coregraphics_symbols.txt"

# Create a combined summary of interesting candidate symbols
echo "# Private Symbol Candidates" > "docs/generated/private_symbols/private_symbol_candidates.md"
echo "Consolidated list of symbols that might relate to Display Mode Reconfiguration." >> "docs/generated/private_symbols/private_symbol_candidates.md"

for f in docs/generated/private_symbols/*_symbols.txt; do
    echo -e "\n## From $(basename "$f")" >> "docs/generated/private_symbols/private_symbol_candidates.md"
    # Try to find specific highly relevant terms
    grep -iE "Mode.*List|Mode.*Count|Reconfigure|Override|UserScale" "$f" | sort | uniq >> "docs/generated/private_symbols/private_symbol_candidates.md"
done

echo "Done scanning."
