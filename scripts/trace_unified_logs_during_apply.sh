#!/bin/bash
OUT_FILE="$1"
DURATION=${2:-120}

echo "Starting log stream. Output will be saved to $OUT_FILE"

# Combine predicate and grep to ensure broad but targeted capture without predicate syntax errors
log stream --predicate 'process == "WindowServer" OR process BEGINSWITH "BetterDisplay" OR subsystem CONTAINS[c] "display" OR subsystem CONTAINS[c] "CoreDisplay" OR subsystem CONTAINS[c] "SkyLight" OR subsystem CONTAINS[c] "WindowServer"' --style compact | grep -iE 'display|mode|resolution|scale|hidpi|low|override|reconfigure|configuration|refresh' > "$OUT_FILE" &
LOG_PID=$!

echo "Log stream running with PID $LOG_PID in background..."

sleep "$DURATION"
kill $LOG_PID 2>/dev/null || true
