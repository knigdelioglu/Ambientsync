# HiDPI Override Reference (Samsung S60UD QHD)

Bu doküman, Samsung S60UD / LS32D60 QHD (DisplayVendorID: `0x4C2D`, DisplayProductID: `0x76AB`) ekranı için macOS WindowServer'ın tanıdığı scale-resolutions plist formatını ve Base64 girdilerini listeler.

## 1. Perfect QHD HiDPI Girdisi Detayları

macOS'in Samsung QHD monitörde native olarak HiDPI (retina) smooth scaling yapabilmesi için, ekranın fiziksel backing çözünürlüğünün 2 katı olan **5120x2880** çözünürlüğünü WindowServer'a bildirmemiz gerekir.

*   **Mantıksal Çözünürlük (Logical/UI):** 2560 x 1440
*   **Backing Çözünürlük (Backing Pixels):** 5120 x 2880
*   **Hex Değeri (Normal):** `00001400 00000B40` (Big Endian)
*   **Hex Değeri (HiDPI/Flexible Flags):** `00001400 00000B40 00000009 00A00000` (5120x2880 @ 9)
*   **Base64 Karşılığı:** `AAAUAAAAC0AAAAAJAKAAAA==`

## 2. Plist Scale-Resolutions Girdileri Listesi

Aşağıdaki girdiler `HiDPIOverridePlistBuilder` tarafından dry-run plist dosyasına kodlanan Base64 listesidir:

| Logical/Backing Size | Base64 String | Açıklama |
| :--- | :--- | :--- |
| **5120x2880 (Normal)** | `AAAUAAAAC0A=` | 5K Backing Resolution |
| **5120x2880 (HiDPI)** | `AAAUAAAAC0AAAAAJAKAAAA==` | Perfect QHD HiDPI Girdisi |
| **3840x2160 (HiDPI)** | `AAAPAAAACDghAAH0AAAAAA==` | 4K HiDPI Girdisi |
| **3200x1800 (HiDPI)** | `AAAMgAAAB4AAAAABACAAAA==` | 3.2K HiDPI Girdisi |
| **2560x1440 (Normal)** | `AAAKAAAABaAAAAABACAAAA==` | QHD Standard Girdi |
| **2560x1440 (HiDPI)** | `AAAKAAAABaAAAAAJAKAAAA==` | QHD HiDPI Girdi |

## 3. Override Plist Dosyasının Yol Yapısı

macOS WindowServer override dosyalarını şu hiyerarşiyle okur:
`/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-[VendorHex]/DisplayProductID-[ProductHex]`

Samsung S60UD için bu yollar:
*   Vendor: `DisplayVendorID-4c2d`
*   Product: `DisplayProductID-76ab`

*Not: Sistem dizinlerine doğrudan yazma engellenmiştir. Plist dosyası `docs/generated/` altında dry-run olarak üretilmektedir.*
