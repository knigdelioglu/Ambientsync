# AmbientSync

AmbientSync, macOS için menü çubuğunda çalışan bir ortam ışığı ve harici ekran yardımcı uygulamasıdır. Ortam ışığı sensörünü kullanarak ekran parlaklığını otomatik ayarlar; ayrıca harici monitör parlaklığı, monitör sesi, HiDPI modu, yazılımsal ekran ayırma ve uyanık tutma özelliklerini tek bir arayüzde sunar.

## Özellikler

- Ortam ışığına göre otomatik parlaklık ayarı
- Yumuşatma, eşik ve hazır profil desteği
- Harici ekran parlaklığını DDC/CI üzerinden kontrol etme
- Monitör sesini macOS ses tuşlarıyla yönlendirme
- HiDPI modunu desteklenen harici ekranlarda açma/kapatma
- Desteklenen harici ekranı kabloyu çıkarmadan macOS masaüstünden yazılımsal olarak ayırma ve yeniden bağlama
- Mac’in uykuya geçmesini geçici veya kalıcı olarak engelleme
- Ekran, EDID, DDC ve HiDPI tanılama araçları
- Tercihleri ve ekran profillerini saklama

## Gereksinimler

- macOS 13 Ventura veya daha yeni bir sürüm
- Xcode Command Line Tools veya Xcode
- Swift 6 araç zinciri
- Otomatik parlaklık için ortam ışığı sensörü erişimi
- Harici monitör parlaklık/ses kontrolü için DDC/CI destekli bağlantı
- Harici monitör parlaklık ve ses kontrolü için `m1ddc` (`/opt/homebrew/bin/m1ddc` veya `/usr/local/bin/m1ddc`)

Yazılımsal ekran ayırma özelliği private SkyLight/CoreGraphics API’lerini çalışma zamanında çözer. Şu anda Samsung S60UD (`vendor 0x4C2D`, `product 0x76AB`) profili üzerinde hedeflenmiştir. Private API davranışı macOS güncellemeleriyle değişebilir; gerekli semboller bulunamazsa özellik güvenli biçimde devre dışı kalır.

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

Yalnız `.app` paketini oluşturmak için:

```bash
INSTALL_APP=0 ./build_app.sh
```

Dağıtıma uygun DMG üretmek için:

```bash
./scripts/build_release_dmg.sh
```

DMG `dist/AmbientSync-<sürüm>.dmg` olarak oluşturulur ve `hdiutil verify` ile doğrulanır. Paket Developer ID ile imzalanmış veya Apple tarafından notarize edilmiş değildir.

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

## Yazılımsal ekran ayırma

Quick Actions içindeki **Harici Ekran** kartından desteklenen monitör **Ayır** ile macOS masaüstü topolojisinden çıkarılabilir; kablo fiziksel olarak bağlı kalır. **Bağla** işlemi private display listesinden güncel ekran kimliğini yeniden çözer ve ekranı geri etkinleştirir.

Güvenlik davranışları:

- Son aktif ekran hiçbir zaman yazılımsal olarak kapatılmaz.
- Mirror setindeki hedef ekran ayırmadan önce güvenli biçimde mirror ilişkisinden çıkarılır.
- Yeniden bağlama sırasında eski `CGDirectDisplayID` değerine güvenilmez; ekran her denemede yeniden enumerate edilir.
- Yeniden bağlama üç kez denenir.
- Soft-disconnect isteği uyku/uyanma sonrasında korunur; sistem ekranı geri açarsa AmbientSync güvenlik koşulları uygunsa tekrar ayırır.
- Yapılandırma `.forSession` kapsamındadır; uygulama/WindowServer davranışında sorun olması halinde yeniden başlatma fiziksel ekranı kalıcı olarak kapalı bırakmaz.

## Proje yapısı

```text
Sources/AmbientSync/   Uygulama kaynak kodu
Tests/                 Birim testleri
Resources/             Uygulama kaynakları ve ikonlar
docs/                  Mimari, tanılama ve HiDPI araştırma notları
Tools/                 Yardımcı araçlar
scripts/               Dağıtım/paketleme scriptleri
build_app.sh           .app paketi oluşturma ve isteğe bağlı kurulum script’i
Package.swift          Swift Package Manager tanımı
Info.plist             macOS uygulama bundle ayarları
```

## Güvenlik ve kapsam sınırları

AmbientSync’in HiDPI akışı `sudo` kullanmaz, `/Library/Displays` altına yazmaz, sanal/dummy/mirror ekran oluşturmaz ve dahili ekranı hedeflemez. Harici ekran işlemleri fingerprint eşleşmesiyle sınırlandırılmıştır.

Yazılımsal ekran ayırma ve HiDPI özellikleri private macOS API’lerine dayandığından Mac App Store dağıtımına uygun kabul edilmemelidir ve macOS güncellemelerinde yeniden doğrulanmalıdır.

GitHub Releases üzerindeki DMG Developer ID ile imzalanmış veya notarize edilmiş değildir. İnternetten indirilen build macOS Gatekeeper uyarısıyla karşılaşabilir.

## Lisans

Bu depoda henüz bir lisans dosyası bulunmamaktadır. Yeniden dağıtım ve katkı koşulları için proje sahibinden izin alınmalıdır.
