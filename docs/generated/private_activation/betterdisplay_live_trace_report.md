# BetterDisplay Live Private Activation Trace

## 1. Başlangıç mode durumu

- Başlangıçta Perfect QHD zaten aktifti.
- Samsung fingerprint: Vendor `0x4c2d`, Product `0x76ab`, Serial `0x30413332`, displayID `3`.
- Active mode: `2560x1440 logical / 5120x2880 backing / 100.0Hz / ioMode 74 / HiDPI true`.
- `duplicateLowResolutionModes=true` count: `107`.
- HiDPI mode count: `49`.
- Perfect QHD mode count: `1`.
- `system_profiler` Samsung için `5120 x 2880` pixels ve `2560 x 1440 @ 100.00Hz` resolution gösterdi.

## 2. BetterDisplay PID ve binary path

- PID: `31936`.
- Binary path: `/Applications/BetterDisplay.app/Contents/MacOS/BetterDisplay`.
- Version: `4.0.4 (45613)`.
- Process command: `/Applications/BetterDisplay.app/Contents/MacOS/BetterDisplay`.
- Loaded app-local dylib: `/Applications/BetterDisplay.app/Contents/Frameworks/libbd.dylib`.

## 3. Linklenen private framework'ler

`otool -L` BetterDisplay binary için şu private/display framework linklerini gösterdi:

- `/System/Library/Frameworks/CoreDisplay.framework/Versions/A/CoreDisplay`
- `/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight`
- `/System/Library/PrivateFrameworks/DisplayServices.framework/Versions/A/DisplayServices`
- `/System/Library/PrivateFrameworks/IOMobileFramebuffer.framework/Versions/A/IOMobileFramebuffer`
- `/System/Library/PrivateFrameworks/CoreBrightness.framework/Versions/A/CoreBrightness`
- `/System/Library/PrivateFrameworks/OSD.framework/Versions/A/OSD`
- `/System/Library/PrivateFrameworks/BezelServices.framework/Versions/A/BezelServices`

## 4. Bulunan kritik semboller

`nm` taramasında BetterDisplay içinde şu unresolved/private semboller bulundu:

- `_IOAVServiceSetVirtualEDIDMode`
- `_SLSDetectDisplays`
- `_SLSMainConnectionID`
- `_SLSDisplaySetUnderscan`
- `_CGSGetDisplayList` -> re-export `SLSGetDisplayList`
- `_CGSGetCurrentDisplayMode` -> re-export `SLSGetCurrentDisplayMode`
- `_CGSConfigureDisplayMode` -> re-export `SLSConfigureDisplayMode`
- `_CoreDisplay_DisplayCreateInfoDictionary`
- Ayrıca çok sayıda `DisplayServices*`, `SLSDisplay*`, `SLSGetZoomParameters*`, `SLSSetDisplayRotation`, `IOMobileFramebufferSetColorRemapMode`.

String taramasında ayrıca `Enable flexible scaling`, `Reinitialize display connection and reload custom configuration`, `Apply Custom EDID`, `autoApplyEDIDOverride`, `displayEDIDOverrideFormat`, `Display mode list update`, `Changing display mode for`, `UI scale matching changing display mode of` metinleri bulundu.

## 5. LLDB attach başarılı mı?

Evet. LLDB PID `31936` process'ine attach oldu, breakpoint kurabildi ve sonra detach edildi.

Not: `SLSMainConnectionID` breakpoint'i Apply öncesi çok sık tetiklendiği için 12 hit sonrası kapatıldı. Diğer breakpoint'ler auto-continue ile açık bırakıldı.

## 6. Tetiklenen breakpoint'ler

Apply sırasında yakalanan kritik breakpoint:

- `CGSConfigureDisplayMode` / `SLSConfigureDisplayMode`
  - Timestamp: `2026-05-20T16:34:04.952132`
  - Thread: main thread, `com.apple.main-thread`
  - Stack özeti:
    - `SkyLight::SLSConfigureDisplayMode`
    - `BetterDisplay` unnamed symbol `1004ff0c0 + 1088`
    - `BetterDisplay` unnamed symbol `100503130 + 192`
    - `BetterDisplay` unnamed symbol `10002db48 + 48`
    - `BetterDisplay` unnamed symbol `10020e65c + 28`
    - main dispatch queue
  - Register özeti: `x0=0x977edd7e0`, `x1=0x3`, `x2=0x38`.

Apply hemen sonrasında yakalanan destek çağrıları:

- `CGSGetCurrentDisplayMode` / `SLSGetCurrentDisplayMode`
  - `SLSCompleteDisplayConfigurationWithOption + 1864` üzerinden display reconfig notify path içinde tetiklendi.
- `CGSGetDisplayList` / `SLSGetDisplayList`
  - `updateAllDisplayInfoAsNeeded`, `display_notify_proc` ve BetterDisplay iç display list refresh stack'lerinde tetiklendi.

Apply dışı/background hit'ler:

- `CGSGetCurrentDisplayMode` HIServices / scale-factor / Dock notification path'inde birkaç kez görüldü; aktivasyon sinyali sayılmadı.

## 7. IOAVServiceSetVirtualEDIDMode çağrıldı mı?

LLDB gözlem penceresinde `IOAVServiceSetVirtualEDIDMode` breakpoint hit'i görülmedi.

Binary bu sembole linkli, yani BetterDisplay bu API'yi kullanabilecek şekilde derlenmiş; fakat bu Apply tekrarında çağrıldığına dair canlı kanıt yakalanmadı.

## 8. SLSDetectDisplays çağrıldı mı?

LLDB gözlem penceresinde `SLSDetectDisplays` breakpoint hit'i görülmedi.

Bu Apply tekrarında yakalanan yol `SLSDetectDisplays` değil, `SLSConfigureDisplayMode` + `SLSCompleteDisplayConfigurationWithOption` sonrası reconfig/display-list refresh gibi görünüyor.

## 9. Diğer kritik private çağrılar

Yakalananlar:

- `SLSConfigureDisplayMode`
- `SLSCompleteDisplayConfigurationWithOption` stack içinde
- `SLSGetCurrentDisplayMode`
- `SLSGetDisplayList`

Linkli ama bu Apply penceresinde hit'i görülmeyenler:

- `IOAVServiceSetVirtualEDIDMode`
- `SLSDetectDisplays`
- `SLSDisplaySetUnderscan`
- `CoreDisplay_DisplayCreateInfoDictionary`

Unified log tarafında Apply zamanı BetterDisplay user-defaults/menu refresh gürültüsü ve WindowServer/IOMobileFramebuffer frame/timestamp akışı çok yoğun. Net, tek satırlık "mode pool injected" veya "EDID virtual mode applied" log'u yakalanmadı.

## 10. Apply öncesi/sonrası mode pool farkı

- Before duplicate-low-res count: `107`.
- After duplicate-low-res count: `107`.
- Before HiDPI count: `49`.
- After HiDPI count: `49`.
- Before active mode: `2560x1440 / 5120x2880 / 100Hz / HiDPI true / ioMode 74`.
- After active mode: `2560x1440 / 5120x2880 / 100Hz / HiDPI true / ioMode 74`.
- `lsof` farkında aktivasyonla ilişkilendirilebilecek yeni framework veya servis handle farkı görülmedi.

## 11. 106 -> 107 geçişi yakalandı mı?

Hayır. Trace başlangıcında mode pool zaten `107` idi ve Apply tekrarından sonra da `107` kaldı.

Bu çalışma 106 -> 107 mode pool injection anını değil, 107 ve Perfect QHD zaten mevcutken yapılan Apply tekrarının private activation path'ini yakaladı.

## 12. En güçlü aktivasyon hipotezi

Bu canlı gözlemde en güçlü hipotez:

BetterDisplay, mode havuzu zaten hazırken Perfect QHD aktivasyonu için `CGSConfigureDisplayMode` re-export'u olan `SLSConfigureDisplayMode` ile display configuration transaction başlatıyor; ardından `SLSCompleteDisplayConfigurationWithOption` display reconfiguration notification zincirini tetikliyor. Bu zincir sonrasında `SLSGetCurrentDisplayMode` ve `SLSGetDisplayList` ile aktif mode ve display list tekrar okunuyor.

Bu, tek başına `SLSDetectDisplays` veya `IOAVServiceSetVirtualEDIDMode` çağrısı gibi görünmedi. Mode pool genişletme mekanizması bu trace'te yakalanmadı, çünkü pool başlangıçta zaten genişlemiş durumdaydı.

## 13. AmbientSync'e aktarılabilecek net çağrı var mı?

Kısmi sinyal var ama aktarılabilecek net ve yeterli çağrı yok.

Yakalanan net çağrı `SLSConfigureDisplayMode`, fakat AmbientSync tarafında `CGSConfigureDisplayMode` denemesi zaten başarısız olduğu için bu tek başına yeterli mekanizma sayılmıyor. BetterDisplay'in başarılı olmasını sağlayan fark muhtemelen çağrı öncesi app-internal mode/config nesnesi, parametre biçimi veya daha önce oluşturulmuş mode pool durumu.

## 14. Net çağrı bulunamadı

Net çağrı bulunamadı.

Bu trace'te aktarılabilir en somut bulgu: Apply sırasında `SLSConfigureDisplayMode` gerçekten çağrılıyor ve hemen ardından `SLSCompleteDisplayConfigurationWithOption` kaynaklı reconfiguration akışı oluşuyor. Ancak 106 -> 107 mode pool yaratma hamlesi, `IOAVServiceSetVirtualEDIDMode` veya `SLSDetectDisplays` ile canlı olarak doğrulanmadı.

