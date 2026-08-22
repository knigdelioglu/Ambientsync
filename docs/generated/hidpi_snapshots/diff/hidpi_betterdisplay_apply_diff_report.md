# HiDPI BetterDisplay Apply Diff Report

Generated at: 2026-05-20T07:52:55Z

## 1. Before snapshot özeti
- Snapshot dir: /Users/kadir/Desktop/Developer/ekle/docs/generated/hidpi_snapshots/before_betterdisplay_apply
- 5120x2880 pixel/backing mode present: false
- 2560x1440 logical / 5120x2880 pixel mode present: false
- Default mode count: 58
- duplicateLowResolutionModes=true mode count: 106
- HiDPI mode count: 48

## 2. After snapshot özeti
- Snapshot dir: /Users/kadir/Desktop/Developer/ekle/docs/generated/hidpi_snapshots/after_betterdisplay_apply
- 5120x2880 pixel/backing mode present: true
- 2560x1440 logical / 5120x2880 pixel mode present: true
- Default mode count: 58
- duplicateLowResolutionModes=true mode count: 107
- HiDPI mode count: 49

## 3. 5120x2880 mode before/after durumu
- Before: false
- After: true
- Strict 2560x1440 logical / 5120x2880 pixel before: false
- Strict 2560x1440 logical / 5120x2880 pixel after: true

## 4. Override dosyası before/after SHA256 farkı
- Before SHA256: 127e69ab6970328c605de85b85f04769febe47077518a2befc4a2273f42000a6
- After SHA256: 127e69ab6970328c605de85b85f04769febe47077518a2befc4a2273f42000a6
- Status: unchanged
- Diff: override_file_sha256.txt.diff

## 5. scale-resolutions farkı
- Override plist dump status: unchanged
- Diff: override_plist_dump.txt.diff

## 6. WindowServer preference farkı
- System WindowServer preferences status: changed
- User WindowServer preferences status: changed
- Diffs: windowserver_preferences_dump.txt.diff, user_windowserver_preferences_dump.txt.diff

## 7. BetterDisplay preference farkı
- BetterDisplay preference/application-support dump status: changed
- Diff: betterdisplay_preferences_dump.txt.diff

## 8. IORegistry/system_profiler farkı
- IORegistry IODisplayConnect status: unchanged
- system_profiler display status: changed
- Diffs: ioreg_IODisplayConnect.txt.diff, ioreg_targeted_display_grep.txt.diff, system_profiler_SPDisplaysDataType.txt.diff, system_profiler_SPDisplaysDataType.json.diff

## 9. Mode pool farkı
- duplicateLowResolutionModes mode pool status: changed
- Default count: 58 -> 58
- duplicateLowResolutionModes count: 106 -> 107
- HiDPI count: 48 -> 49
- Diffs: cg_mode_pool_summary.json.diff, cg_mode_pool_default.md.diff, cg_mode_pool_duplicate_low_res.md.diff

## 10. BetterDisplay'in ek olarak ne yaptığına dair en güçlü hipotez
5120x2880 geri geldiyse ve override SHA256 aynıysa, en güçlü iz WindowServer/display preference state değişimi veya bu state'i yeniden yükleten bir display reinitialize akışı.

## 11. AmbientSync'in bunu bağımsız yapabilmesi için gereken eksik parça
AmbientSync'in eksik parçası, override plist varlığından sonra macOS/WindowServer'ın mode pool'u hangi public veya private reinitialize adımıyla yeniden hesapladığını güvenilir şekilde tetikleyebilmek. Bu snapshot seti, bunun kalıcı preference değişimi mi yoksa runtime-only display services çağrısı mı olduğunu ayırmak için toplandı.

## 12. Hangi yaklaşım öneriliyor?
Önce bu rapordaki değişen diff dosyaları incelenmeli. WindowServer plist değişiyorsa gelecekte sadece ilgili state'in güvenli ve kullanıcı onaylı yönetimi araştırılmalı; kalıcı plist değişmiyor ama mode pool değişiyorsa public API ile display reconfiguration tetikleme yolları ve uygulama yeniden başlatma/reconnect davranışı ayrı spike olarak denenmeli.

## 13. Hâlâ yapılamayanlar
- BetterDisplay'in private API veya runtime çağrıları bu araçla doğrudan gözlenmez.
- WindowServer'ın bellekteki state'i yalnızca dolaylı olarak IORegistry, system_profiler, preferences ve CoreGraphics mode pool çıktılarından anlaşılır.
- Bu araç hiçbir çözünürlük apply etmez, virtual/dummy/mirror oluşturmaz ve BetterDisplay CLI/API kullanmaz.

## 14. Build sonucu
Bu rapor build sonucunu otomatik varsaymaz. En güncel build sonucu için proje kökünde `swift build` çıktısına bakın.
