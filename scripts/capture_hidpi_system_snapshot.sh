#!/usr/bin/env bash
set -u
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_DIR="${2:-"$ROOT_DIR/docs/generated/hidpi_snapshots"}"
BEFORE_DIR="$BASE_DIR/before_betterdisplay_apply"
AFTER_DIR="$BASE_DIR/after_betterdisplay_apply"
DIFF_DIR="$BASE_DIR/diff"
TARGET_OVERRIDE="/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-4c2d/DisplayProductID-76ab"

usage() {
  cat <<EOF
Usage:
  scripts/capture_hidpi_system_snapshot.sh before [snapshot_base_dir]
  scripts/capture_hidpi_system_snapshot.sh after [snapshot_base_dir]
  scripts/capture_hidpi_system_snapshot.sh diff [snapshot_base_dir]

This tool is read-only for system/display state. It writes captured output only under:
  $BASE_DIR
EOF
}

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

run_text() {
  local output_file="$1"
  shift
  {
    echo "\$ $*"
    echo
    "$@"
    local status=$?
    echo
    echo "[exit_status] $status"
    return "$status"
  } >"$output_file" 2>&1
}

append_command() {
  local output_file="$1"
  shift
  {
    echo
    echo "## $*"
    echo
    "$@"
    local status=$?
    echo
    echo "[exit_status] $status"
  } >>"$output_file" 2>&1
}

ambient_sync_bin() {
  local built="$ROOT_DIR/.build/debug/AmbientSync"
  if [[ -x "$built" ]]; then
    printf '%s\n' "$built"
  else
    printf '%s\n' "swift run AmbientSync"
  fi
}

run_swift_snapshot() {
  local snapshot_dir="$1"
  local bin
  bin="$(ambient_sync_bin)"
  if [[ "$bin" == "swift run AmbientSync" ]]; then
    (cd "$ROOT_DIR" && swift run AmbientSync --hidpi-system-snapshot "$snapshot_dir") \
      >"$snapshot_dir/swift_snapshot_reporter.log" 2>&1
  else
    "$bin" --hidpi-system-snapshot "$snapshot_dir" \
      >"$snapshot_dir/swift_snapshot_reporter.log" 2>&1
  fi
}

dump_override() {
  local snapshot_dir="$1"
  {
    echo "Path: $TARGET_OVERRIDE"
    if [[ -f "$TARGET_OVERRIDE" ]]; then
      echo "Exists: true"
      echo -n "SHA256: "
      shasum -a 256 "$TARGET_OVERRIDE" | awk '{print $1}'
    else
      echo "Exists: false"
      echo "SHA256: n/a"
    fi
  } >"$snapshot_dir/override_file_sha256.txt" 2>&1

  {
    echo "# Override plist dump"
    echo "Path: $TARGET_OVERRIDE"
    echo
    if [[ -f "$TARGET_OVERRIDE" ]]; then
      plutil -p "$TARGET_OVERRIDE"
      echo
      echo "# scale-resolutions quick checks"
      local xml
      xml="$(plutil -convert xml1 -o - "$TARGET_OVERRIDE" 2>/dev/null || true)"
      local scale_count
      scale_count="$(printf '%s\n' "$xml" | grep -c "<data>" || true)"
      echo "scale-resolutions data record count (approx): $scale_count"
      if printf '%s\n' "$xml" | grep -q "AAAUAAAAC0A="; then
        echo "5120x2880 normal record base64 present: true"
      else
        echo "5120x2880 normal record base64 present: false"
      fi
      if printf '%s\n' "$xml" | grep -q "AAAUAAAAC0AAAAAJAKAAAA=="; then
        echo "5120x2880 HiDPI/flexible record base64 present: true"
      else
        echo "5120x2880 HiDPI/flexible record base64 present: false"
      fi
    else
      echo "Override file is missing."
    fi
  } >"$snapshot_dir/override_plist_dump.txt" 2>&1
}

dump_windowserver_preferences() {
  local snapshot_dir="$1"
  local system_out="$snapshot_dir/windowserver_preferences_dump.txt"
  local user_out="$snapshot_dir/user_windowserver_preferences_dump.txt"
  : >"$system_out"
  : >"$user_out"

  for file in \
    /Library/Preferences/com.apple.windowserver.displays.plist \
    /Library/Preferences/com.apple.windowserver.plist \
    /Library/Preferences/ByHost/com.apple.windowserver*.plist
  do
    [[ -e "$file" ]] || continue
    append_command "$system_out" ls -lOe "$file"
    append_command "$system_out" plutil -p "$file"
  done

  for file in \
    "$HOME"/Library/Preferences/com.apple.windowserver*.plist \
    "$HOME"/Library/Preferences/ByHost/com.apple.windowserver*.plist
  do
    [[ -e "$file" ]] || continue
    append_command "$user_out" ls -lOe "$file"
    append_command "$user_out" plutil -p "$file"
  done
}

dump_betterdisplay_preferences() {
  local snapshot_dir="$1"
  local out="$snapshot_dir/betterdisplay_preferences_dump.txt"
  : >"$out"

  for file in \
    "$HOME"/Library/Preferences/*BetterDisplay*.plist \
    "$HOME"/Library/Preferences/*betterdisplay*.plist
  do
    [[ -e "$file" ]] || continue
    append_command "$out" ls -lOe "$file"
    append_command "$out" plutil -p "$file"
  done

  for path in \
    "$HOME"/Library/Application\ Support/*BetterDisplay* \
    "$HOME"/Library/Application\ Support/*betterdisplay* \
    /Library/Application\ Support/*BetterDisplay* \
    /Library/Application\ Support/*betterdisplay*
  do
    [[ -e "$path" ]] || continue
    append_command "$out" ls -ldOe "$path"
    if [[ -d "$path" ]]; then
      append_command "$out" find "$path" -maxdepth 3 -print
      while IFS= read -r plist_file; do
        append_command "$out" ls -lOe "$plist_file"
        append_command "$out" plutil -p "$plist_file"
      done < <(find "$path" -maxdepth 3 -type f -name "*.plist" 2>/dev/null)
    elif [[ "$path" == *.plist ]]; then
      append_command "$out" plutil -p "$path"
    fi
  done
}

dump_relevant_listing() {
  local snapshot_dir="$1"
  local out="$snapshot_dir/filesystem_relevant_listing.txt"
  : >"$out"

  append_command "$out" find /Library/Displays/Contents/Resources/Overrides -maxdepth 3 \( -iname "*4c2d*" -o -iname "*76ab*" -o -iname "*samsung*" \) -exec ls -ldOe {} \;
  append_command "$out" find /Library/Preferences -maxdepth 2 \( -iname "*windowserver*" -o -iname "*display*" -o -iname "*betterdisplay*" \) -exec ls -ldOe {} \;
  append_command "$out" find "$HOME/Library/Preferences" -maxdepth 2 \( -iname "*windowserver*" -o -iname "*display*" -o -iname "*betterdisplay*" \) -exec ls -ldOe {} \;
  append_command "$out" find "$HOME/Library/Application Support" -maxdepth 2 \( -iname "*BetterDisplay*" -o -iname "*betterdisplay*" \) -exec ls -ldOe {} \;
}

capture_snapshot() {
  local label="$1"
  local snapshot_dir
  case "$label" in
    before) snapshot_dir="$BEFORE_DIR" ;;
    after) snapshot_dir="$AFTER_DIR" ;;
    *) usage; exit 2 ;;
  esac

  mkdir -p "$snapshot_dir"
  timestamp >"$snapshot_dir/timestamp.txt"

  run_text "$snapshot_dir/system_profiler_SPDisplaysDataType.txt" system_profiler SPDisplaysDataType
  run_text "$snapshot_dir/system_profiler_SPDisplaysDataType.json" system_profiler SPDisplaysDataType -json

  run_text "$snapshot_dir/ioreg_IODisplayConnect.txt" ioreg -lw0 -r -c IODisplayConnect
  {
    echo "# IORegistry targeted grep output"
    echo "# grep DisplayVendorID"
    ioreg -lw0 | grep -i -A20 -B20 "DisplayVendorID"
    echo "[exit_status] ${PIPESTATUS[*]}"
    echo
    echo "# grep 4c2d"
    ioreg -lw0 | grep -i -A20 -B20 "4c2d"
    echo "[exit_status] ${PIPESTATUS[*]}"
    echo
    echo "# grep 76ab"
    ioreg -lw0 | grep -i -A20 -B20 "76ab"
    echo "[exit_status] ${PIPESTATUS[*]}"
  } >"$snapshot_dir/ioreg_targeted_display_grep.txt" 2>&1

  run_swift_snapshot "$snapshot_dir"
  dump_override "$snapshot_dir"
  dump_windowserver_preferences "$snapshot_dir"
  dump_betterdisplay_preferences "$snapshot_dir"
  dump_relevant_listing "$snapshot_dir"

  echo "Snapshot written: $snapshot_dir"
}

extract_summary_value() {
  local file="$1"
  local label="$2"
  if [[ -f "$file" ]]; then
    grep -F -- "- $label:" "$file" | head -n 1 | sed "s|^- $label: ||"
  else
    printf 'missing'
  fi
}

file_sha_line() {
  local file="$1"
  if [[ -f "$file" ]]; then
    grep "^SHA256:" "$file" | head -n 1 | sed "s/^SHA256: //"
  else
    printf 'missing'
  fi
}

changed_text() {
  local before_file="$1"
  local after_file="$2"
  if [[ ! -f "$before_file" && ! -f "$after_file" ]]; then
    printf 'not captured'
  elif cmp -s "$before_file" "$after_file"; then
    printf 'unchanged'
  else
    printf 'changed'
  fi
}

write_diff_file() {
  local name="$1"
  local before_file="$BEFORE_DIR/$name"
  local after_file="$AFTER_DIR/$name"
  if [[ -f "$before_file" || -f "$after_file" ]]; then
    diff -u "$before_file" "$after_file" >"$DIFF_DIR/${name}.diff" 2>&1 || true
  fi
}

generate_diff_report() {
  mkdir -p "$DIFF_DIR"

  for name in \
    cg_mode_pool_summary.json \
    cg_active_displays.md \
    cg_mode_pool_default.md \
    cg_mode_pool_duplicate_low_res.md \
    hidpi_summary.md \
    override_file_sha256.txt \
    override_plist_dump.txt \
    windowserver_preferences_dump.txt \
    user_windowserver_preferences_dump.txt \
    betterdisplay_preferences_dump.txt \
    filesystem_relevant_listing.txt \
    ioreg_IODisplayConnect.txt \
    ioreg_targeted_display_grep.txt \
    system_profiler_SPDisplaysDataType.txt \
    system_profiler_SPDisplaysDataType.json
  do
    write_diff_file "$name"
  done

  local before_summary="$BEFORE_DIR/hidpi_summary.md"
  local after_summary="$AFTER_DIR/hidpi_summary.md"
  local before_5120 after_5120 before_strict after_strict before_default after_default before_dup after_dup before_hidpi after_hidpi
  before_5120="$(extract_summary_value "$before_summary" "5120x2880 pixel/backing mode present")"
  after_5120="$(extract_summary_value "$after_summary" "5120x2880 pixel/backing mode present")"
  before_strict="$(extract_summary_value "$before_summary" "2560x1440 logical / 5120x2880 pixel mode present")"
  after_strict="$(extract_summary_value "$after_summary" "2560x1440 logical / 5120x2880 pixel mode present")"
  before_default="$(extract_summary_value "$before_summary" "Default mode count")"
  after_default="$(extract_summary_value "$after_summary" "Default mode count")"
  before_dup="$(extract_summary_value "$before_summary" "duplicateLowResolutionModes=true mode count")"
  after_dup="$(extract_summary_value "$after_summary" "duplicateLowResolutionModes=true mode count")"
  before_hidpi="$(extract_summary_value "$before_summary" "HiDPI mode count")"
  after_hidpi="$(extract_summary_value "$after_summary" "HiDPI mode count")"

  local before_sha after_sha
  before_sha="$(file_sha_line "$BEFORE_DIR/override_file_sha256.txt")"
  after_sha="$(file_sha_line "$AFTER_DIR/override_file_sha256.txt")"

  local override_status windowserver_status user_windowserver_status betterdisplay_status ioreg_status profiler_status mode_status
  override_status="$(changed_text "$BEFORE_DIR/override_plist_dump.txt" "$AFTER_DIR/override_plist_dump.txt")"
  windowserver_status="$(changed_text "$BEFORE_DIR/windowserver_preferences_dump.txt" "$AFTER_DIR/windowserver_preferences_dump.txt")"
  user_windowserver_status="$(changed_text "$BEFORE_DIR/user_windowserver_preferences_dump.txt" "$AFTER_DIR/user_windowserver_preferences_dump.txt")"
  betterdisplay_status="$(changed_text "$BEFORE_DIR/betterdisplay_preferences_dump.txt" "$AFTER_DIR/betterdisplay_preferences_dump.txt")"
  ioreg_status="$(changed_text "$BEFORE_DIR/ioreg_IODisplayConnect.txt" "$AFTER_DIR/ioreg_IODisplayConnect.txt")"
  profiler_status="$(changed_text "$BEFORE_DIR/system_profiler_SPDisplaysDataType.txt" "$AFTER_DIR/system_profiler_SPDisplaysDataType.txt")"
  mode_status="$(changed_text "$BEFORE_DIR/cg_mode_pool_duplicate_low_res.md" "$AFTER_DIR/cg_mode_pool_duplicate_low_res.md")"

  local hypothesis
  if [[ "$after_5120" == "true" && "$before_sha" == "$after_sha" ]]; then
    if [[ "$windowserver_status" == "changed" || "$user_windowserver_status" == "changed" ]]; then
      hypothesis="5120x2880 geri geldiyse ve override SHA256 aynıysa, en güçlü iz WindowServer/display preference state değişimi veya bu state'i yeniden yükleten bir display reinitialize akışı."
    elif [[ "$betterdisplay_status" == "changed" ]]; then
      hypothesis="5120x2880 geri geldiyse, override SHA256 aynıysa ve sistem preference farkı görünmüyorsa, BetterDisplay runtime reinitialize/private display call tetikliyor olabilir."
    else
      hypothesis="5120x2880 geri geldiyse ve kalıcı dosya farkı zayıfsa, tetikleyici büyük olasılıkla WindowServer/IOKit runtime state reinitialization."
    fi
  elif [[ "$before_sha" != "$after_sha" ]]; then
    hypothesis="Override SHA256 değişti; BetterDisplay yakaladığımız plistten farklı içerik üretmiş veya dosyayı güncellemiş olabilir. override_plist_dump.txt.diff byte/plist düzeyindeki ilk kanıt."
  elif [[ "$after_5120" != "true" ]]; then
    hypothesis="After snapshot'ta 5120x2880 hâlâ görünmüyor; bu koşulda BetterDisplay de mode pool'u yeniden üretememiş kabul edilmeli."
  else
    hypothesis="Kanıtlar karışık; mode pool, WindowServer preference ve IORegistry diff dosyaları birlikte okunmalı."
  fi

  cat >"$DIFF_DIR/hidpi_betterdisplay_apply_diff_report.md" <<EOF
# HiDPI BetterDisplay Apply Diff Report

Generated at: $(timestamp)

## 1. Before snapshot özeti
- Snapshot dir: $BEFORE_DIR
- 5120x2880 pixel/backing mode present: $before_5120
- 2560x1440 logical / 5120x2880 pixel mode present: $before_strict
- Default mode count: $before_default
- duplicateLowResolutionModes=true mode count: $before_dup
- HiDPI mode count: $before_hidpi

## 2. After snapshot özeti
- Snapshot dir: $AFTER_DIR
- 5120x2880 pixel/backing mode present: $after_5120
- 2560x1440 logical / 5120x2880 pixel mode present: $after_strict
- Default mode count: $after_default
- duplicateLowResolutionModes=true mode count: $after_dup
- HiDPI mode count: $after_hidpi

## 3. 5120x2880 mode before/after durumu
- Before: $before_5120
- After: $after_5120
- Strict 2560x1440 logical / 5120x2880 pixel before: $before_strict
- Strict 2560x1440 logical / 5120x2880 pixel after: $after_strict

## 4. Override dosyası before/after SHA256 farkı
- Before SHA256: $before_sha
- After SHA256: $after_sha
- Status: $(if [[ "$before_sha" == "$after_sha" ]]; then echo "unchanged"; else echo "changed"; fi)
- Diff: override_file_sha256.txt.diff

## 5. scale-resolutions farkı
- Override plist dump status: $override_status
- Diff: override_plist_dump.txt.diff

## 6. WindowServer preference farkı
- System WindowServer preferences status: $windowserver_status
- User WindowServer preferences status: $user_windowserver_status
- Diffs: windowserver_preferences_dump.txt.diff, user_windowserver_preferences_dump.txt.diff

## 7. BetterDisplay preference farkı
- BetterDisplay preference/application-support dump status: $betterdisplay_status
- Diff: betterdisplay_preferences_dump.txt.diff

## 8. IORegistry/system_profiler farkı
- IORegistry IODisplayConnect status: $ioreg_status
- system_profiler display status: $profiler_status
- Diffs: ioreg_IODisplayConnect.txt.diff, ioreg_targeted_display_grep.txt.diff, system_profiler_SPDisplaysDataType.txt.diff, system_profiler_SPDisplaysDataType.json.diff

## 9. Mode pool farkı
- duplicateLowResolutionModes mode pool status: $mode_status
- Default count: $before_default -> $after_default
- duplicateLowResolutionModes count: $before_dup -> $after_dup
- HiDPI count: $before_hidpi -> $after_hidpi
- Diffs: cg_mode_pool_summary.json.diff, cg_mode_pool_default.md.diff, cg_mode_pool_duplicate_low_res.md.diff

## 10. BetterDisplay'in ek olarak ne yaptığına dair en güçlü hipotez
$hypothesis

## 11. AmbientSync'in bunu bağımsız yapabilmesi için gereken eksik parça
AmbientSync'in eksik parçası, override plist varlığından sonra macOS/WindowServer'ın mode pool'u hangi public veya private reinitialize adımıyla yeniden hesapladığını güvenilir şekilde tetikleyebilmek. Bu snapshot seti, bunun kalıcı preference değişimi mi yoksa runtime-only display services çağrısı mı olduğunu ayırmak için toplandı.

## 12. Hangi yaklaşım öneriliyor?
Önce bu rapordaki değişen diff dosyaları incelenmeli. WindowServer plist değişiyorsa gelecekte sadece ilgili state'in güvenli ve kullanıcı onaylı yönetimi araştırılmalı; kalıcı plist değişmiyor ama mode pool değişiyorsa public API ile display reconfiguration tetikleme yolları ve uygulama yeniden başlatma/reconnect davranışı ayrı spike olarak denenmeli.

## 13. Hâlâ yapılamayanlar
- BetterDisplay'in private API veya runtime çağrıları bu araçla doğrudan gözlenmez.
- WindowServer'ın bellekteki state'i yalnızca dolaylı olarak IORegistry, system_profiler, preferences ve CoreGraphics mode pool çıktılarından anlaşılır.
- Bu araç hiçbir çözünürlük apply etmez, virtual/dummy/mirror oluşturmaz ve BetterDisplay CLI/API kullanmaz.

## 14. Build sonucu
Bu rapor build sonucunu otomatik varsaymaz. En güncel build sonucu için proje kökünde \`swift build\` çıktısına bakın.
EOF

  echo "Diff report written: $DIFF_DIR/hidpi_betterdisplay_apply_diff_report.md"
}

case "${1:-}" in
  before)
    capture_snapshot before
    ;;
  after)
    capture_snapshot after
    generate_diff_report
    ;;
  diff)
    generate_diff_report
    ;;
  *)
    usage
    exit 2
    ;;
esac
