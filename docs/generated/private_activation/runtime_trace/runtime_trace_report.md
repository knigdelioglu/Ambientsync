# HiDPI Runtime Trace Report

## 1. Özet
Bu rapor BetterDisplay'in Perfect QHD aktivasyonu sırasında sistemde oluşan preference, log ve mode pool değişikliklerini analiz eder.

## 2. Before durumu
- Default Mode Count: 58
- Duplicate Low-Res Count: 106
- Perfect QHD Mevcut Mu?: Hayır

## 3. After durumu
- Default Mode Count: 58
- Duplicate Low-Res Count: 107
- Perfect QHD Mevcut Mu?: Evet

## 4. Mode pool farkı
Default Pool Farkı: 0
Duplicate Low-Res Pool Farkı: +1

## 5. Eklenen mode
- Perfect QHD (Logical 2560x1440, Backing 5120x2880) başarıyla eklendi.

## 6. system_profiler farkı
- Farkları detaylı incelemek için `diff system_profiler_SPDisplaysDataType.txt` komutu kullanılabilir.

## 7. WindowServer preference farkı
- `com.apple.windowserver.displays.plist` üzerinde değişiklikler tespit edilebilir.

## 8. BetterDisplay preference farkı
- `pro.betterdisplay.BetterDisplay` loglandı.

## 9. Unified log ipuçları
Unified log incelemesi `during/unified_log_during_apply.txt` içinde.

## 10. XPC/service/process ipuçları
Loglardan tespit edilmesi beklenen muhtemel servisler: CoreDisplay, WindowServer XPC.

## 11. En güçlü activation hipotezi
WindowServer üzerinden preference reload veya `SLSRequestDisplayReconfiguration` benzeri bir komut ile mode pool'un yenilendiği düşünülmektedir.

## 12. Live private deney için adaylar
- WindowServer preferences reload komutları
- SLSRequestDisplayReconfiguration (veya CGS- karşılığı)

## 13. Mode apply/set kategorisine alınan ama şu an denenmeyecek çağrılar
- `CGSConfigureDisplayMode` (Sadece mode pool'da halihazırda var olduğunda kullanılabilir)
- `CGDisplaySetDisplayMode`

## 14. Sonraki önerilen deney
Eğer After snapshot'ta Perfect QHD gelmediyse ilk başarılı snapshot ile kıyaslanmalı. Eğer geldiyse, unified log içindeki event mesajlarına göre (WindowServer reload) bir sonraki deney yazılmalı.
