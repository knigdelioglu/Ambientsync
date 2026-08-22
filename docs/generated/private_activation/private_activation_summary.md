# Private HiDPI Activation - Setup & Discovery Summary

## 1. Eklenen Dosyalar
- `Sources/AmbientSync/DisplayControl/Experimental/HiDPIPrivateActivationSafety.swift`
- `Sources/AmbientSync/DisplayControl/Experimental/PrivateDisplaySymbolResolver.swift`
- `Sources/AmbientSync/DisplayControl/Experimental/PrivateActivationExperiment.swift`
- `Sources/AmbientSync/DisplayControl/Experimental/PrivateHiDPIActivationEngine.swift`
- `scripts/scan_private_symbols.sh`

Ayrıca `PreferencesView.swift` içerisine geliştirici modunda (`#if DEBUG`) görünen kırmızı uyarılı `Experimental Private HiDPI Activation` paneli eklendi.

## 2. Normal Build Private Koddan Temiz mi?
Evet. Hem `#if DEBUG` ve `#else let EXPERIMENTAL_PRIVATE_HIDPI = false` bayraklarıyla, hem de statik `isExperimentAllowed()` kontrolüyle yayın (release) build'inin ve debug dışı ortamların özel API'leri çağırması tamamen engellendi. UI paneli de release modunda gizlendi. `swift build` ile test edildi, hatasız ve sorunsuz derlendi.

## 3. Experimental Build Nasıl Açılıyor?
Varsayılan olarak `swift build` komutu (Debug konfigurasyonuyla) `EXPERIMENTAL_PRIVATE_HIDPI = true` olarak derleniyor. Böylece Preferences sayfasındaki panel açılıyor. Sadece `swift build -c release` dendiğinde kapanıyor.

## 4. Hangi Private Framework Sembolleri Bulundu?
Çalıştırılan statik sembol arama aracıyla (`scan_private_symbols.sh`) yeni nesil macOS sistemlerinde (Big Sur+) private framework'lerin doğrudan dosya sistemi üzerinde (`/System/Library/PrivateFrameworks/`) düz metin olarak yer almadığı, `dyld shared cache` içinde bulunduğu doğrulandı. 

Bu sebeple statik bash aracı yerine Swift içinden `dlopen` ve `dlsym` ile çalışma zamanında (runtime) tarama yapan `PrivateDisplaySymbolResolver.swift` geliştirildi. Uygulama açılıp "Scan Private Display Symbols" tuşuna basıldığında bu sınıf üzerinden:
- `CGSConfigureDisplayMode`
- `CoreDisplay_DisplayCreateInfoDictionary`
- `CGDisplayModeGetPixelsWide`
ve diğer kritik `SkyLight` / `CoreDisplay` sembollerinin adresleri çalışma zamanında saptanacak.

## 5. Hangi Semboller Aday?
Experiment A için `SkyLight` içerisindeki `CGSConfigureDisplayMode`.
Experiment B için `CoreDisplay` içerisindeki `CoreDisplay_DisplayCreateInfoDictionary`.

## 6. Hiç Gerçek Private Çağrı Yapıldı mı?
**Hayır.** Şu an `PrivateActivationExperiment.swift` sadece "Dry Run" (kuru prova) yapıyor. `dlsym` ile sembollerin hafızada bulunup bulunmadığını kontrol edip raporluyor, ancak bu sembolleri C fonksiyon pointerlarına cast edip çağırmıyor. Yanlış signature ile sistemin crash olmasını engellemek için henüz çağrı yok.

## 7. Yapıldıysa Perfect QHD Oluştu mu?
Henüz çağrı yapılmadı. Sonraki adımda Dry Run raporundaki adrese göre Swift `@convention(c)` signature'ları yazılıp çağrı denenecek.

## 8. Güvenlik Guard'ları Çalışıyor mu?
Evet. `HiDPIPrivateActivationSafety.shared` üzerinden 3 katmanlı güvenlik devrede:
- Sadece `DEBUG` / Experimental build altında çalışır.
- `CGDisplayIsBuiltin` ise anında engeller. (Built-in ekrana müdahale edilemez).
- Display Vendor ID (`0x4C2D`), Product ID (`0x76AB`) ve Serial (`0x30413332`) eşleşmiyorsa anında engeller.

## 9. Sonraki Deney Önerisi
Kullanıcı uygulamayı başlatıp Preferences içinden **"Scan Private Display Symbols"** tuşuna basmalı ve `docs/generated/private_activation/symbol_scan_report.md` dosyasının başarıyla dolduğunu doğrulamalıdır. 

Bunun ardından, bulunan CGS ve SLS metotları için `typealias` signature tanımlamaları yazılarak **Experiment A** için ilk "Gerçek" (Live) private API çağrısı yapılabilir.
