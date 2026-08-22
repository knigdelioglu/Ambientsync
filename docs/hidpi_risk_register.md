# HiDPI Risk Register & Mitigations

Bu doküman, macOS native HiDPI mod geçişleri ve override süreçlerine ilişkin riskleri, güvenlik sınırlarını ve mitigasyon stratejilerini tanımlar.

## 1. Dahili Ekran Güvenlik Riski

*   **Risk:** Dahili retina ekranına (MacBook Pro/Air yerleşik ekranları) yanlışlıkla override plist uygulanması veya geçersiz bir mod basılması sonucu ekranın tamamen kapanması (black screen) veya bozulması.
*   **Önem Derecesi:** Kritik / Yüksek
*   **Mitigasyon:** 
    *   `HiDPITargetDisplayResolver` içinde `CGDisplayIsBuiltin(displayID) != 0` kontrolü yapılarak dahili ekranlar işleme alınmadan kesinlikle bypass edilir.
    *   `NativeDisplayModeReader` dahili ekran ID'si tespit edilirse boş mod listesi döner.
    *   `HiDPIModeApplier` dahili ekrana mod basılmasını en başta engeller.

## 2. macOS Sistem Dosyalarına Yazma Riski

*   **Risk:** `/Library/Displays/Contents/Resources/Overrides` altına sudo veya AppleScript yetkilendirmesiyle doğrudan yazılması sonucu macOS SIP (System Integrity Protection) veya dosya izinlerinin bozulması, sistemin açılmaması.
*   **Önem Derecesi:** Yüksek
*   **Mitigasyon:**
    *   `installOverride` fonksiyonu pasif (`.requiresPrivilegedInstaller`) olarak kurgulanmıştır ve sistem dizinine asla yazma yapmaz.
    *   Dosyalar sadece dry-run olarak `docs/generated/` altına yazılır. Kullanıcı dosyayı dilerse kendisi manuel olarak kopyalayabilir.

## 3. Ekran Uyku/Wake Sonrası Siyah Ekran veya Mod Kaybı Riski

*   **Risk:** Monitör uykudan uyandığında veya kablo sökülüp takıldığında macOS WindowServer'ın geçici olarak kararsız modlar listelemesi ve yanlış modun basılmasıyla ekranın uyanmaması.
*   **Önem Derecesi:** Orta
*   **Mitigasyon:**
    *   `HiDPIReapplyService` didWake veya display parameters değiştiğinde hemen mod basmaz. **2 saniyelik debounce/stabilizasyon gecikmesi** bekler.
    *   Mod basılmadan önce Samsung monitörün VendorID/ProductID ve Serial değerleri tekrar doğrulanır.
    *   Kayıtlı fingerprint mod listesinde yoksa reapply işlemi iptal edilir ve hiçbir işlem yapılmaz.
