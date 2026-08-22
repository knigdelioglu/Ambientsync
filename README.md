# AmbientSync

AmbientSync, macOS için menü çubuğunda çalışan bir ortam ışığı ve harici ekran yardımcı uygulamasıdır. Ortam ışığı sensörünü kullanarak ekran parlaklığını otomatik ayarlar; ayrıca harici monitör parlaklığı, monitör sesi, HiDPI modu ve uyanık tutma özelliklerini tek bir arayüzde sunar.

## Özellikler

- Ortam ışığına göre otomatik parlaklık ayarı
- Yumuşatma, eşik ve hazır profil desteği
- Harici ekran parlaklığını DDC/CI üzerinden kontrol etme
- Monitör sesini macOS ses tuşlarıyla yönlendirme
- HiDPI modunu desteklenen harici ekranlarda açma/kapatma
- Mac’in uykuya geçmesini geçici veya kalıcı olarak engelleme
- Ekran, EDID, DDC ve HiDPI tanılama araçları
- Tercihleri ve ekran profillerini saklama

## Gereksinimler

- macOS 13 Ventura veya daha yeni bir sürüm
- Xcode Command Line Tools veya Xcode
- Swift 6 araç zinciri
- Otomatik parlaklık için ortam ışığı sensörü erişimi
- Harici monitör parlaklık/ses kontrolü için DDC/CI destekli bağlantı

## Derleme ve çalıştırma

Swift Package Manager ile debug derlemesi:

```bash
swift build
```

Release derlemesi:

```bash
swift build -c release
```

Testleri çalıştırma:

```bash
swift test
```

Uygulama paketi oluşturup `/Applications` altına kurma:

```bash
./build_app.sh
```

Bu script `AmbientSync.app` paketini oluşturur ve mevcut uygulama paketini `/Applications/AmbientSync.app` konumuna kopyalar. Uygulamayı kaldırmak için Finder veya aşağıdaki komut kullanılabilir:

```bash
rm -rf /Applications/AmbientSync.app
```

## Tanılama komutları

Release executable’ı üzerinden bazı tanılama akışları çalıştırılabilir:

```bash
.build/release/AmbientSync --diagnostic
.build/release/AmbientSync --hidpi-mode-pool-diagnostic
.build/release/AmbientSync --cgs-mode-enumeration
.build/release/AmbientSync --cgs-mode74-without-betterdisplay
.build/release/AmbientSync --cgs-mode74-apply-experiment
.build/release/AmbientSync --hidpi-activation-spike
```

Sistem anlık görüntüsü almak için çıktı klasörü belirtilebilir:

```bash
.build/release/AmbientSync --hidpi-system-snapshot /tmp/ambientsync-snapshot
```

Tanılama çıktıları ve araştırma notları `docs/` altında tutulur.

## HiDPI desteği hakkında

HiDPI akışı şu anda belirli bir Samsung QHD harici ekran profili için doğrulanmıştır. Uygulama ekranın EDID/fingerprint bilgisini eşleştirmeden CGS mode değişikliği yapmaz. Çalışan profil, sistemdeki display override dosyasının ve ilgili CGS mode’larının mevcut olmasına bağlıdır.

Bu nedenle HiDPI davranışı:

- tüm monitörlerde garanti edilmez,
- macOS sürüm ve WindowServer değişikliklerinden etkilenebilir,
- desteklenen ekran profili ve sistem durumu doğrulanmadan uygulanmaz.

HiDPI araştırmasının ayrıntıları için [`docs/hidpi_final_status.md`](docs/hidpi_final_status.md) ve [`AmbientSync_HiDPI_Kesif_Raporu.md`](AmbientSync_HiDPI_Kesif_Raporu.md) dosyalarına bakın.

## Proje yapısı

```text
Sources/AmbientSync/   Uygulama kaynak kodu
Tests/                 Birim testleri
Resources/             Uygulama kaynakları ve ikonlar
docs/                  Mimari, tanılama ve HiDPI araştırma notları
Tools/                 Yardımcı araçlar
build_app.sh           .app paketi oluşturma ve kurulum script’i
Package.swift          Swift Package Manager tanımı
Info.plist             macOS uygulama bundle ayarları
```

## Güvenlik ve kapsam sınırları

AmbientSync’in HiDPI akışı `sudo` kullanmaz, `/Library/Displays` altına yazmaz, sanal/dummy/mirror ekran oluşturmaz ve dahili ekranı hedeflemez. Harici ekran işlemleri fingerprint eşleşmesiyle sınırlandırılmıştır.

Uygulama henüz imzalanmış veya notarize edilmiş bir dağıtım paketi olarak sunulmamaktadır. GitHub’dan klonlanan bir build, macOS Gatekeeper uyarılarıyla karşılaşabilir.

## Lisans

Bu depoda henüz bir lisans dosyası bulunmamaktadır. Yeniden dağıtım ve katkı koşulları için proje sahibinden izin alınmalıdır.
