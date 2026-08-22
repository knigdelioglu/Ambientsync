# HiDPI Test Plan & Verification

Bu doküman, AmbientSync native HiDPI modüllerini test etmek ve doğrulamak için tasarlanmış manuel ve otomatik test adımlarını içerir.

## 1. Otomatik Unit Test Senaryoları

Proje altındaki test paketine eklenebilecek sanal/mock veri senaryoları:

*   **Test Case 1: Built-in Display Bypass**
    *   *Girdi:* Dahili ekran ID'si (`CGDisplayIsBuiltin` true olan bir mock ID).
    *   *Beklenen Çıktı:* `HiDPITargetDisplayResolver` bu ID'yi bypass etmeli, `NativeDisplayModeReader` boş mod dönmeli, `HiDPIModeApplier` hatayla sonlanmalı.
*   **Test Case 2: Samsung Display Match**
    *   *Girdi:* VendorID: `0x4C2D`, ProductID: `0x76AB`.
    *   *Beklenen Çıktı:* `HiDPITargetDisplayResolver` Samsung ekranı başarıyla algılamalı.
*   **Test Case 3: Fingerprint Serialization**
    *   *Girdi:* `DisplayModeFingerprint` oluşturma ve UserDefaults'a kaydetme.
    *   *Beklenen Çıktı:* Saklanan fingerprint'in decode edildiğinde birebir uyuşması.

## 2. Manuel Test Adımları

Uygulama arayüzünden test etme adımları:

### Adım A: Dry-Run Plist Testi
1. AmbientSync Preferences penceresini açın.
2. Samsung S60UD ekranı bağlıysa, "Native HiDPI Configuration (Dry-Run)" kartının geldiğini doğrulayın.
3. "Dry-Run Plist Üret" butonuna basın.
4. `docs/generated/` altında plist dosyasının ve `hidpi_override_summary.md` raporunun oluştuğunu doğrulayın.

### Adım B: Karşılaştır / Doğrula Testi
1. "Karşılaştır / Doğrula" butonuna basın.
2. Sistemde (varsa) kurulu plist ile üretilen plistin karşılaştırma özetini okuyun.

### Adım C: Debounce ve Reapply Testi
1. HiDPI modunu aktif edin.
2. Ekran kablosunu söküp takın veya Mac'i uyutup uyandırın.
3. 2 saniye sonra ekran modunun stabil şekilde eski haline (QHD HiDPI) geldiğini doğrulayın.
