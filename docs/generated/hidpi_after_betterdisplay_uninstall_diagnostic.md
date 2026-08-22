# HiDPI After BetterDisplay Uninstall Diagnostic

Generated at: 2026-05-20 11:00 Europe/Istanbul

## 1. Özet

BetterDisplay kaldırıldıktan ve AmbientSync açıldıktan sonraki current snapshot, HiDPI kaybının override dosyasının silinmesinden kaynaklanmadığını gösteriyor.

Sistem override dosyası hâlâ mevcut, SHA256 beklenen değerle aynı ve plist içinde `5120x2880` normal + HiDPI/flexible `scale-resolutions` kayıtları duruyor. Buna rağmen CoreGraphics `duplicateLowResolutionModes=true` mode pool artık Perfect QHD HiDPI modunu üretmiyor.

Sonuç sınıflandırması: **B) Override var ama mode pool’da Perfect QHD yok**.

## 2. Sistem override durumu

Kontrol edilen dosya:

`/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-4c2d/DisplayProductID-76ab`

- Dosya var: evet
- SHA256: `127e69ab6970328c605de85b85f04769febe47077518a2befc4a2273f42000a6`
- Beklenen SHA256 ile aynı: evet
- `scale-resolutions` kayıt sayısı: yaklaşık 28
- `5120x2880` normal kayıt var: evet, `0000140000000B40`
- `5120x2880` HiDPI/flexible kayıt var: evet, `0000140000000B400000000900A00000`
- Eski çalışan snapshot ile override SHA/plist farkı: yok

## 3. Reference backup durumu

Kontrol edilen uygulama kopyaları:

- `Sources/AmbientSync/Resources/HiDPIOverrides/Samsung_4C2D_76AB_reference.plist`
- `~/Library/Application Support/AmbientSync/HiDPIOverrides/DisplayVendorID-4c2d/DisplayProductID-76ab`

SHA256 değerleri:

- Bundled reference: `127e69ab6970328c605de85b85f04769febe47077518a2befc4a2273f42000a6`
- Application Support backup: `127e69ab6970328c605de85b85f04769febe47077518a2befc4a2273f42000a6`
- System override ile aynı: evet

## 4. Aktif ekran durumu

CoreGraphics active display list:

- Aktif ekran sayısı: 2
- Built-in ekran: DisplayID `1`, built-in `true`
- Samsung ekran: DisplayID `2`
- Samsung Vendor ID: `0x4C2D`
- Samsung Product ID: `0x76AB`
- Samsung Serial: `0x30413332`
- Built-in: `false`
- Online: `true`
- Active: `true`
- Virtual/dummy/mirror ekran belirtisi: yok
- Mirror durumu: system_profiler Samsung için `Mirror: Off`

Not: DisplayID çalışan snapshot’ta `3`, güncel snapshot’ta `2`. Vendor/product/serial değişmediği için bu fingerprint değişimi sayılmıyor.

## 5. Mode pool durumu

Güncel CoreGraphics mode pool:

- Default mode count: `58`
- `duplicateLowResolutionModes=true` mode count: `106`
- HiDPI mode count: `48`
- Default listede Perfect QHD var: hayır
- Duplicate-low-res listede Perfect QHD var: hayır

Aranan Perfect QHD:

- Logical: `2560x1440`
- Pixel/backing: `5120x2880`
- Refresh: `100Hz`
- HiDPI: `true`
- Strong HiDPI: `true`

Güncel duplicate-low-res listesinin ilk modu artık normal QHD:

- Logical: `2560x1440`
- Pixel/backing: `2560x1440`
- Refresh: `100Hz`
- HiDPI: `false`
- Candidate reason: `logical-2560x1440`

Çalışan eski snapshot’ta aynı listenin ilk modu Perfect QHD idi:

- Logical: `2560x1440`
- Pixel/backing: `5120x2880`
- Refresh: `100Hz`
- HiDPI: `true`
- Strong HiDPI: `true`
- Candidate reason: `logical-2560x1440,pixel-5120x2880,strong-hidpi-16:9,100hz-hidpi,strict-perfect-qhd`

## 6. Aktif mode durumu

Güncel Samsung aktif modu:

- Active logical width/height: `2560x1440`
- Active pixel width/height: `2560x1440`
- Refresh: `100Hz`
- isHiDPI: `false`
- isStrongHiDPI: `false`
- isPerfectQHDHiDPI: `false`

Çalışan eski snapshot:

- Active logical width/height: `2560x1440`
- Active pixel width/height: `5120x2880`
- Refresh: `100Hz`
- isHiDPI: `true`
- isStrongHiDPI: `true`
- isPerfectQHDHiDPI: `true`

## 7. system_profiler durumu

Güncel `system_profiler SPDisplaysDataType` Samsung bölümü:

- Display name: `LS32D60xU`
- Resolution: `2560 x 1440 (QHD/WQHD - Wide Quad High Definition)`
- UI Looks like: `2560 x 1440 @ 100.00Hz`
- Mirror: `Off`
- Online: `Yes`
- Rotation: `Supported`

Güncel JSON alanları:

- Display ID: `2`
- Vendor ID: `4c2d`
- Product ID: `76ab`
- Serial: `30413332`
- Pixels: `2560 x 1440`
- Resolution: `2560 x 1440 @ 100.00Hz`

Çalışan eski snapshot farkı:

- Eski: `Resolution: 5120 x 2880 (5K/UHD+ - Ultra High Definition Plus)`
- Güncel: `Resolution: 2560 x 1440 (QHD/WQHD - Wide Quad High Definition)`
- `UI Looks like: 2560 x 1440 @ 100.00Hz` değişmemiş, fakat backing resolution 5K’dan QHD’ye düşmüş.

## 8. WindowServer preference durumu

Read-only kontrol edilen dosyalar:

- `/Library/Preferences/com.apple.windowserver.displays.plist`
- `/Library/Preferences/com.apple.windowserver.plist`
- `~/Library/Preferences/ByHost/com.apple.windowserver.displays*.plist`

Güncel dump içinde Samsung ile uyumlu görünen kayıtlar hâlâ mevcut:

- `Scale => 2`
- `Wide => 2560`
- `High => 1440`
- `Hz => 100`
- `Depth => 8` veya `Depth => 4` varyantları
- `CurrentInfo` ve `UnmirrorInfo` blokları mevcut

Eski çalışan WindowServer dump ile güncel dump arasında içerik farkı görünmedi; sadece dosya timestamp/mtime satırları değişti. Bu önemli: `Scale=2 Wide=2560 High=1440 Hz=100` preference kaydının diskte durması, CoreGraphics mode pool’un Perfect QHD modunu üretmesi için tek başına yeterli değil.

## 9. Çalışan eski snapshot ile farklar

Karşılaştırılan eski çalışan snapshot dosyaları:

- `docs/generated/hidpi_snapshots/after_betterdisplay_apply/cg_mode_pool_summary.json`
- `docs/generated/hidpi_snapshots/after_betterdisplay_apply/cg_active_displays.md`
- `docs/generated/hidpi_snapshots/after_betterdisplay_apply/system_profiler_SPDisplaysDataType.txt`
- `docs/generated/hidpi_snapshots/after_betterdisplay_apply/windowserver_preferences_dump.txt`
- `docs/generated/hidpi_snapshots/after_betterdisplay_apply/user_windowserver_preferences_dump.txt`

Fark özeti:

- Override değişmiş mi: hayır
- Reference/backup değişmiş mi: hayır
- Display fingerprint değişmiş mi: hayır, DisplayID değişmiş ama vendor/product/serial aynı
- Mode pool değişmiş mi: evet
- Duplicate-low-res count: `107 -> 106`
- HiDPI mode count: `49 -> 48`
- Perfect QHD duplicate-low-res mode: `var -> yok`
- Aktif mode değişmiş mi: evet, `5120x2880 backing HiDPI -> 2560x1440 non-HiDPI`
- system_profiler değişmiş mi: evet, `Resolution 5120 x 2880 -> 2560 x 1440`
- WindowServer preference içeriği değişmiş mi: hayır, yalnızca metadata/timestamp değişmiş görünüyor

## 10. Sonuç sınıflandırması

**B) Override var ama mode pool’da Perfect QHD yok**

Gerekçe:

- Sistem override doğru ve SHA256 aynı.
- `scale-resolutions` içinde `5120x2880` normal ve HiDPI/flexible kayıtları var.
- Samsung ekran doğru fingerprint ile bağlı.
- Fakat `duplicateLowResolutionModes=true` listesinde `2560x1440 logical / 5120x2880 pixel / 100Hz / strong HiDPI` mod yok.

İkincil gözlem:

- WindowServer’da `Scale=2 Wide=2560 High=1440 Hz=100` kayıtları hâlâ görünüyor, bu yüzden sınıf D tek başına doğru değil. Sorun diskteki WindowServer preference kaydının kaybolması değil; runtime mode pool’un 5K backing modu yeniden üretmemesi.

## 11. Teknik sebep

BetterDisplay Apply sonrası macOS runtime display configuration, override plist içeriğini kullanarak `5120x2880` backing mode’u CoreGraphics duplicate-low-res pool’a eklemişti. BetterDisplay kaldırıldıktan sonra override dosyası ve WindowServer preference kaydı diskte kalsa bile bu runtime activation/reconfigure state’i artık mevcut değil.

Bu nedenle AmbientSync açıldığında `HiDPIModeApplier` için uygulanabilir Perfect QHD `CGDisplayMode` objesi yok. Güvenlik gereği AmbientSync mode listesinde olmayan çözünürlüğü elle üretip uygulamamalı; mevcut davranış burada doğru şekilde duruyor.

## 12. Sonraki önerilen adım

Yeni özellik yazmadan bug sınıflandırması net: plist kurulumu değil, activation/reconfigure eksik.

Önerilen sonraki spike:

- BetterDisplay’in Apply sırasında diskte kalıcı olarak neyi değiştirdiğinden çok, WindowServer/CoreGraphics mode pool’u hangi runtime display reconfiguration adımıyla yeniden hesaplatabildiğini izole etmek.
- Public API ile yapılabilecek güvenli activation denemeleri ayrı bir deney planında ele alınmalı.
- O zamana kadar AmbientSync yalnızca duplicate-low-res listesinde gerçekten var olan `CGDisplayMode` objesini uygulamalı; listede yoksa “Activation Engine gerekli” tanısı vermeli.

Build sonucu:

- `swift build` başarılı.
