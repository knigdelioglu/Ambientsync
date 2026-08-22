# Captured BetterDisplay Override Summary

Bu dosya, BetterDisplay kaldırılmadan önce çalışan Samsung QHD HiDPI override plist dosyasının canonical referans olarak yakalandığını gösterir.

## 1. Kaynak ve hedefler

- **Kaynak:** `/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-4c2d/DisplayProductID-76ab`
- **Proje referansı:** `Sources/AmbientSync/Resources/HiDPIOverrides/Samsung_4C2D_76AB_reference.plist`
- **Docs/generated kopyası:** `docs/generated/captured_betterdisplay_override.plist`
- **Application Support yedeği:** `~/Library/Application Support/AmbientSync/HiDPIOverrides/DisplayVendorID-4c2d/DisplayProductID-76ab`

## 2. SHA256

Tüm kopyalar birebir eşleşir:

- **SHA256:** `127e69ab6970328c605de85b85f04769febe47077518a2befc4a2273f42000a6`

## 3. Vendor / Product

- **Vendor ID:** `0x4C2D`
- **Product ID:** `0x76AB`
- **Serial:** `0x30413332`

## 4. scale-resolutions doğrulaması

- **Kayıt sayısı:** `28`
- **5120x2880 normal kayıt:** mevcut
  - Hex: `0000140000000B40`
- **5120x2880 HiDPI/flexible kayıt:** mevcut
  - Hex: `0000140000000B400000000900A00000`

## 5. Neden önemli

- Bu plist, BetterDisplay kaldırılmadan önce güvenli şekilde yakalandı.
- Bu dosya yalnızca Samsung `0x4C2D / 0x76AB` ekran için referanstır.
- macOS bu override dosyasını uygulama klasöründen değil, `/Library/Displays/Contents/Resources/Overrides/` altından okur.

## 6. Güvenlik notu

- `/Library` altında yazma yapılmadı.
- Mevcut sistem dosyası silinmedi veya ezilmedi.
- Application Support yedeği kullanıcı alanında tutulur.
