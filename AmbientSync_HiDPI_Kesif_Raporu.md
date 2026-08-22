# AmbientSync Native HiDPI Keşif ve Sonuç Raporu

> Amaç: Bu belge, AmbientSync projesinde Samsung QHD harici ekranda BetterDisplay olmadan çalışan HiDPI çözümünü ve bu çözüme ulaşırken elenen yolları kayıt altına almak için hazırlanmıştır.  
> İleride projede bozulma, refactor, macOS güncellemesi veya yeni monitör desteği sırasında aynı keşif sürecinin tekrar yaşanmaması için proje kökünde saklanmalıdır.

---

## 1. Hedef

AmbientSync uygulamasında harici Samsung QHD ekranda sanal ekran/dummy/mirror kullanmadan native HiDPI moduna geçmek istedik.

Hedef ekran:

```text
Display: Samsung LS32D60xU / Samsung QHD
Vendor ID: 0x4C2D
Product ID: 0x76AB
Serial: 0x30413332
Built-in: false
```

Hedef mod:

```text
Logical/UI çözünürlük: 2560×1440
Backing/pixel çözünürlük: 5120×2880
Refresh: 100Hz
HiDPI: true
Strong HiDPI: true
```

Normal mod:

```text
Logical/UI çözünürlük: 2560×1440
Backing/pixel çözünürlük: 2560×1440
Refresh: 100Hz
HiDPI: false
```

---

## 2. Başta yanlış sandığımız şey

Başlangıç varsayımı şuydu:

```text
BetterDisplay bir runtime “refresh / reload / activation” çağrısı yapıyor.
Biz o çağrıyı bulursak macOS mode pool’a 5120×2880 HiDPI mode’u ekleyecek.
```

Bu varsayım eksik çıktı.

Gerçek çözümde kritik nokta şuydu:

```text
Public CoreGraphics mode listesi yeterli değil.
Asıl kullanılabilir mode listesi CGS / SkyLight internal mode listesindedir.
```

Yani sorun yalnızca “mode üretmek” değilmiş; doğru mode zaten CGS internal listesinde bulunabiliyor, fakat public API her zaman bunu yeterli biçimde göstermiyor veya uygulamaya elverişli hale getirmiyor.

---

## 3. BetterDisplay’in yaptığına dair ilk bulgular

BetterDisplay aktifken şu durum gözlendi:

```text
duplicateLowResolutionModes=true public mode count: 107
HiDPI mode count: 49
Perfect QHD mode: var
Active mode: 2560×1440 logical / 5120×2880 backing @100Hz
```

BetterDisplay kaldırıldığında veya HiDPI kapalıyken daha önce şu durum görülmüştü:

```text
duplicateLowResolutionModes=true public mode count: 106
HiDPI mode count: 48
Perfect QHD mode: yok
Active mode: 2560×1440 logical / 2560×1440 backing @100Hz
```

Bu yüzden uzun süre BetterDisplay’in mode pool’a “+1 mode” ekleyen özel bir activation motoru olduğu düşünüldü.

---

## 4. Override dosyası keşfi

BetterDisplay’in Samsung ekran için kullandığı override dosyası bulundu:

```text
/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-4c2d/DisplayProductID-76ab
```

Doğrulanan SHA256:

```text
127e69ab6970328c605de85b85f04769febe47077518a2befc4a2273f42000a6
```

Override içinde doğrulanan önemli kayıtlar:

```text
5120×2880 normal:
0000140000000B40

5120×2880 HiDPI/flexible:
0000140000000B400000000900A00000
```

Bu dosyanın yedekleri alındı:

```text
Sources/AmbientSync/Resources/HiDPIOverrides/Samsung_4C2D_76AB_reference.plist
~/Library/Application Support/AmbientSync/HiDPIOverrides/DisplayVendorID-4c2d/DisplayProductID-76ab
docs/generated/captured_betterdisplay_override.plist
```

Önemli sonuç:

```text
Override dosyası doğru olsa bile tek başına yeterli değildir.
Asıl uygulanabilir mode seçimi CGS internal mode listesi üzerinden yapılmalıdır.
```

---

## 5. Denenen ve çalışmayan yollar

Aşağıdaki yollar denendi ve hedef Perfect QHD modunu üretmek veya seçmek için yeterli olmadığı görüldü.

### 5.1 Public CoreGraphics refresh / transaction denemeleri

Denenenler:

```text
soft refresh
100Hz → 60Hz → 100Hz toggle
refresh-rate nudge
CGDisplayConfiguration transaction
arrangement no-op transaction
```

Sonuç:

```text
Mode pool değişmedi.
Perfect QHD üretilmedi.
```

---

### 5.2 SLSDetectDisplays

Deneme sonucu:

```text
SLSMainConnectionID: başarılı
SLSDetectDisplays result: 0
Mode Count Change: 106 -> 106
Perfect QHD oluşmadı
```

Sonuç:

```text
SLSDetectDisplays tek başına yeterli değil.
```

---

### 5.3 CGSConfigureDisplayMode tek başına

Deneme sonucu:

```text
CGSConfigureDisplayMode çağrısı Result: 1001 döndü.
Perfect QHD oluşmadı.
```

Sonuç:

```text
Mode pool’da hedef mode yoksa CGSConfigureDisplayMode tek başına işe yaramıyor.
```

---

### 5.4 SLS / CGS display transaction zinciri

BetterDisplay trace içinde şu akış yakalandı:

```text
CGBeginDisplayConfiguration
→ CGSConfigureDisplayMode
→ CGCompleteDisplayConfiguration(option: 2)
→ internal refresh
```

AmbientSync içinde bu zincir taklit edildi.

Sonuç:

```text
SLS transaction reproduced but did not create Perfect QHD.
```

Yani transaction zinciri tek başına mode üretmedi.

---

### 5.5 IOAVServiceSetVirtualEDIDMode

BetterDisplay binary’sinde bu sembol bulundu:

```text
IOAVServiceSetVirtualEDIDMode
```

Fakat HiDPI aktivasyon sırasında LLDB breakpoint hiç tetiklenmedi.

Sonuç:

```text
Bu HiDPI activation akışında IOAVServiceSetVirtualEDIDMode kullanılmıyor.
```

---

### 5.6 BetterDisplay binary / stack analizi

BetterDisplay’de şu fonksiyon bölgeleri incelendi:

```text
0x1004ff0c0
0x100503130
0x10002db48
0x10020e65c
0x1006af0c0
```

Bulgular:

```text
0x1006af0c0:
SLSCopyDisplayInfoDictionary → fallback CoreDisplay_DisplayCreateInfoDictionary
displayConfigurationId / persistedDisplayID / storedIdentifiers / defaultModeNumber / defaultIsHiDPI state güncellemesi

0x1004ff0c0:
CGSGetCurrentDisplayMode
CGSGetNumberOfDisplayModes
CGSConfigureDisplayMode
CGCompleteDisplayConfiguration(option: 2)
```

Önemli sonuç:

```text
BetterDisplay’in display identity / mode cache hazırlığı var.
Fakat taşınabilir tek bir upstream private çağrı bulunamadı.
```

---

## 6. Asıl kırılma noktası: CGS internal mode enumeration

Sonunda kritik test yapıldı:

```text
CGSGetCurrentDisplayMode
CGSGetNumberOfDisplayModes
CGSGetDisplayModeDescriptionOfLength
```

Bu testte public CoreGraphics listesinden daha geniş bir CGS internal mode listesi olduğu görüldü.

Örnek sonuç:

```text
CGS mode count: 126
Public default mode count: 58
Public duplicateLowResolutionModes=true count: 107
```

En önemli iki mode:

```text
Mode 56:
2560×1440 logical / 2560×1440 backing @100Hz
HiDPI: false
lowRes: true

Mode 74:
2560×1440 logical / 5120×2880 backing @100Hz
HiDPI: true
lowRes: false
```

Yani hedef Perfect QHD HiDPI mode, Samsung ekran için CGS internal listesinde şu ID ile görüldü:

```text
Perfect QHD mode id: 74
Normal QHD mode id: 56
```

---

## 7. Çalışan çözüm

Çalışan mekanizma:

```text
CGS internal mode listesini tara
→ Normal QHD mode’u bul
→ Perfect QHD HiDPI mode’u bul
→ CGS display transaction ile istenen mode id’ye geç
```

Samsung ekran için doğrulanan geçişler:

```text
Mode 56 = HiDPI kapalı / normal QHD
Mode 74 = HiDPI açık / Perfect QHD
```

Çalışan transaction:

```text
CGBeginDisplayConfiguration
CGSConfigureDisplayMode(config, displayID, selectedModeID)
CGCompleteDisplayConfiguration(config, option: 2)
```

Başarılı test:

```text
Mode 56 ↔ Mode 74 geçişi AmbientSync içinde çalıştı.
BetterDisplay silindikten ve MacBook yeniden başlatıldıktan sonra da çalıştı.
```

Bu sonuç, BetterDisplay’in artık gerekli olmadığını gösterir; ancak sistem override dosyasının korunması önemlidir.

---

## 8. Public API testi sonucu

Ayrı bir public CoreGraphics testinde yalnızca şu public API’ler kullanıldı:

```text
CGGetActiveDisplayList
CGDisplayCopyAllDisplayModes(..., kCGDisplayShowDuplicateLowResolutionModes=true)
CGDisplaySetDisplayMode
```

Sonuç:

```text
target display found
public mode count: 106
normal QHD candidate bulundu
public HiDPI candidate bulunamadı
Apply Public HiDPI blocked
Apply Public Normal QHD succeeded
```

Yani:

```text
Private API olmadan Perfect QHD mode public listede bulunamadı.
App Store-safe public CoreGraphics yöntemi bu sistemde HiDPI geçişi sağlayamadı.
```

---

## 9. App Store durumu

Çalışan çözüm şu private / undocumented API katmanına dayanır:

```text
CGS / SLS / SkyLight internal mode enumeration
CGSGetNumberOfDisplayModes
CGSGetDisplayModeDescriptionOfLength
CGSConfigureDisplayMode
CGCompleteDisplayConfiguration(option: 2)
```

Bu nedenle:

```text
Bu özellik App Store’a uygun değildir.
```

Olası dağıtım stratejisi:

```text
App Store build:
- private API yok
- HiDPI mode switch yok veya yalnızca public mode varsa sınırlı çalışır

Direct/private build:
- CGS mode scanner + CGS mode switch içerir
- Developer ID / notarized direct distribution veya kişisel kullanım
```

---

## 10. Başka monitörlere genelleme

Mode ID’ler evrensel değildir.

Bu Samsung ekran için:

```text
Normal QHD = 56
Perfect QHD = 74
```

Başka monitörde bu numaralar değişebilir.

Doğru genel algoritma:

```text
1. Harici ekranı fingerprint ile tanı.
2. CGS internal mode listesini tara.
3. Normal QHD adayı bul:
   logical 2560×1440
   pixel 2560×1440
   refresh 100Hz
   HiDPI false

4. Perfect QHD HiDPI adayı bul:
   logical 2560×1440
   pixel 5120×2880
   refresh 100Hz
   HiDPI true

5. Bulunan modeID neyse onu uygula.
```

Samsung için `56/74` yalnızca doğrulanmış fallback olarak tutulmalıdır. Ana akış hardcoded mode ID ile çalışmamalıdır.

---

## 11. Uygulama içinde korunması gereken nihai mimari

### 11.1 Güvenlik kuralları

Her zaman korunmalı:

```text
Built-in display’e işlem yapılmaz.
Samsung fingerprint doğrulanmadan işlem yapılmaz.
Mode description doğrulanmadan apply yapılmaz.
Mode listesinde olmayan çözünürlük uygulanmaz.
Virtual/dummy/mirror display oluşturulmaz.
BetterDisplay CLI/API çağrılmaz.
sudo kullanılmaz.
```

### 11.2 Ana servisler

Önerilen ana yapı:

```text
CGSModeScanner
- CGS internal mode listesini okur
- mode adaylarını çıkarır

CGSModeSwitcher
- doğrulanmış modeID’ye geçiş yapar
- CGBeginDisplayConfiguration + CGSConfigureDisplayMode + CGCompleteDisplayConfiguration kullanır

HiDPIModeSelector
- en iyi normal ve HiDPI adaylarını dinamik seçer

HiDPIStateStore
- kullanıcının HiDPI açık/kapalı tercihini saklar

HiDPIReapplyService
- uygulama açılışında / ekran uyanınca kullanıcı tercihine göre güvenli reapply yapar
```

### 11.3 UI

Ana UI teknik mode ID göstermemeli:

```text
HiDPI Aç
HiDPI Kapat
Mevcut Mod: 2560×1440 / 5120×2880 @100Hz
```

Diagnostic UI gösterebilir:

```text
CGS current mode id
CGS mode count
Normal candidate id
HiDPI candidate id
Samsung fallback used
Override SHA256 match
```

---

## 12. Final karar

Bu keşfin nihai sonucu:

```text
BetterDisplay’in gizli activation motorunu birebir kopyalamaya gerek kalmadı.
Asıl çözüm, public CoreGraphics listesi yerine CGS internal mode listesini okumak ve doğru mode ID’yi seçmek oldu.
```

Samsung ekran için çalışan sonuç:

```text
Mode 56 → Normal QHD
Mode 74 → Perfect QHD HiDPI
```

BetterDisplay silindikten ve reboot sonrası test sonucu:

```text
AmbientSync çalışmaya devam etti.
Mode 74 kalıcı kaldı.
BetterDisplay artık gerekli değil.
```

Ancak:

```text
Sistem override dosyası korunmalıdır.
macOS güncellemesi, display override temizliği veya AppCleaner/CleanMyMac gibi araçlar mode 74’ün kaybolmasına neden olabilir.
Böyle bir durumda CGS mode scanner diagnostic tekrar çalıştırılmalıdır.
```

---

## 13. İleride sorun çıkarsa kontrol listesi

Eğer HiDPI tekrar çalışmazsa şu sırayla kontrol et:

```text
1. Samsung ekran fingerprint doğru mu?
   Vendor: 0x4C2D
   Product: 0x76AB
   Serial: 0x30413332

2. Override dosyası duruyor mu?
   /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-4c2d/DisplayProductID-76ab

3. Override SHA256 doğru mu?
   127e69ab6970328c605de85b85f04769febe47077518a2befc4a2273f42000a6

4. CGS mode count kaç?
   Beklenen: yaklaşık 126

5. Mode 56 var mı?
   2560×1440 → 2560×1440 @100Hz

6. Mode 74 var mı?
   2560×1440 → 5120×2880 @100Hz

7. Public duplicate listte HiDPI görünmese bile CGS listesine bak.

8. Mode 74 yoksa:
   Override/configuration yeniden kurulmalı veya BetterDisplay/override generator benzeri ilk aktivasyon gerekebilir.

9. Mode 74 varsa ama geçiş çalışmıyorsa:
   CGS transaction zincirini kontrol et:
   CGBeginDisplayConfiguration
   CGSConfigureDisplayMode
   CGCompleteDisplayConfiguration(option: 2)
```

---

## 14. Kısa özet

```text
Başta BetterDisplay’in tek bir private tetikleyiciyle HiDPI mode ürettiğini sandık.
SLSDetectDisplays, IOAVServiceSetVirtualEDIDMode, public refresh ve SLS transaction gibi yolları denedik; çalışmadı.
Sonunda asıl farkın public CoreGraphics listesi ile CGS internal mode listesi arasında olduğunu bulduk.
CGS internal listesinde Mode 74, hedef Perfect QHD HiDPI moduydu.
Mode 56/74 geçişi AmbientSync içinde çalıştı.
BetterDisplay silinip reboot sonrası da çalıştı.
Public API-only yöntem başarısız oldu.
Nihai çözüm: CGS internal mode scanner + doğrulanmış modeID apply.
