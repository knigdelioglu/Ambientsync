# HiDPI Reboot / Reconnect Test

## Mevcut durum

- Override plist doğru.
- SHA256 doğru.
- Samsung fingerprint doğru.
- Mode pool'da 106 mode var.
- Ancak Perfect QHD HiDPI (`2560x1440` logical / `5120x2880` backing / `100 Hz`) şu anda macOS mode listesinde görünmüyor.

## Beklenen gözlem

- Reboot, kablo çıkar-tak, veya sleep/wake sonrası mode pool yeniden yüklenirse Perfect QHD mode listede görünmeli.
- Görünmüyorsa sorun override içeriğinde değil, macOS mode pool reinitialize sürecindedir.

## Diagnostic adımları

### Reboot sonrası

1. AmbientSync diagnostic çalıştır.
2. Active display list'ini kontrol et.
3. Samsung fingerprint doğrula.
4. `duplicateLowResolutionModes=true` mode count ve HiDPI count'u kaydet.
5. Strict / loose Perfect QHD var mı bak.

### Kablo çıkar-tak sonrası

1. Samsung ekranı çıkar ve tekrar tak.
2. Aynı diagnostic'i tekrar çalıştır.
3. Perfect QHD mode görünüyorsa sorun pool reload idi.

### Sleep / wake sonrası

1. Sistemi uykuya al ve uyandır.
2. Diagnostic'i tekrar çalıştır.
3. Perfect QHD mode görünüyorsa sorun geçici reinitialize idi.

## Başarılı sayılacak sonuç

- Samsung fingerprint eşleşiyor.
- Override SHA256 eşleşiyor.
- `duplicateLowResolutionModes=true` listesinde Strict veya Loose Perfect QHD mode görünüyor.
- Mode apply yalnızca listedeki mode ile yapılabiliyor.

## Başarısız sayılacak sonuç

- Perfect QHD mode hiçbir diagnostic turunda görünmüyor.
- Serialsız fallback ile otomatik reapply tetikleniyor.
- Built-in ekran veya listede olmayan mode'a apply yapılıyor.
