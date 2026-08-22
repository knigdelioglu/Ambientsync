#!/bin/bash
BASE_DIR="docs/generated/private_activation/runtime_trace"
BEFORE_DIR="$BASE_DIR/before"
AFTER_DIR="$BASE_DIR/after"
DURING_DIR="$BASE_DIR/during"
DIFF_DIR="$BASE_DIR/diff"
REPORT_PATH="$BASE_DIR/runtime_trace_report.md"

mkdir -p "$BEFORE_DIR" "$AFTER_DIR" "$DURING_DIR" "$DIFF_DIR"

echo "================================================="
echo "  HiDPIRuntimeTraceSpike - BetterDisplay Trace   "
echo "================================================="
echo "1. Taking 'before' snapshot..."
./scripts/capture_runtime_display_state.sh "$BEFORE_DIR"

echo "2. Starting Unified Log stream in background..."
./scripts/trace_unified_logs_during_apply.sh "$DURING_DIR/unified_log_during_apply.txt" 180 &
LOG_TRACE_PID=$!

echo ""
echo ">>> LÜTFEN ŞİMDİ BETTERDISPLAY'İ MANUEL AÇIN <<<"
echo ">>> Samsung ekran için Flexible Scaling / Apply işlemini yapın."
echo ">>> Perfect QHD (Logical 2560x1440, Backing 5120x2880) oluştuğunu gördüğünüzde:"
read -p ">>> ENTER TUŞUNA BASIN..."

echo ""
echo "3. Stopping log stream..."
kill $LOG_TRACE_PID 2>/dev/null || true

echo "4. Taking 'after' snapshot..."
./scripts/capture_runtime_display_state.sh "$AFTER_DIR"

echo "5. Running Trace Analyzer..."
cat Sources/AmbientSync/DisplayControl/Experimental/HiDPIRuntimeTraceAnalyzer.swift > /tmp/AnalyzerFull.swift
cat << 'EOF' >> /tmp/AnalyzerFull.swift

// Standalone execution entry point
let args = CommandLine.arguments
if args.count >= 6 {
    let analyzer = HiDPIRuntimeTraceAnalyzer()
    analyzer.generateReport(beforeDir: args[1], afterDir: args[2], duringDir: args[3], diffDir: args[4], reportPath: args[5])
} else {
    print("Insufficient arguments for Trace Analyzer.")
}
EOF

swift /tmp/AnalyzerFull.swift "$BEFORE_DIR" "$AFTER_DIR" "$DURING_DIR" "$DIFF_DIR" "$REPORT_PATH"

echo "Trace analysis complete."
echo "Report generated at: $REPORT_PATH"
