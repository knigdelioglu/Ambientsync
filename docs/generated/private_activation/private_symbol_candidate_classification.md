# Private Symbol Candidate Classification (Refined)

Buna göre yapılan ikinci tur tarama (RTLD_DEFAULT & dyld image inspection) sonuçları:

## 1. Bulunan ve Doğrulanan Semboller (RTLD_DEFAULT)
- ✅ `CoreDisplay_DisplayCreateInfoDictionary` (CoreDisplay)
- ✅ `CGSCopyDisplayInfoDictionary` (SkyLight/CoreGraphics)
- ✅ `CGSConfigureDisplayMode` (SkyLight)
- ✅ `CGDisplaySetDisplayMode` (SkyLight)

## 2. Aranan Ama Bulunamayan (Reload/Refresh) Sembolleri
- ❌ `SLSRequestDisplayReconfiguration`
- ❌ `CGSRequestDisplayReconfiguration`
- ❌ `SLSDisplayModeRefreshList`
- ❌ `CoreDisplay_DisplayModeRefreshList`
- ❌ `CGSReloadDisplayConfiguration`
- ❌ `CGSDisplayConfigReload`

## 3. Durum Özeti
**Bu aşamada güvenli live reload/reconfigure adayı bulunamadı.**

Eldeki sembollerden `CGSConfigureDisplayMode` ve `CGDisplaySetDisplayMode` sadece "apply/set" işlemi yaptığı ve mode pool'da olmayan bir modu (Perfect QHD) üretmediği için aday listesinden çıkarılmıştır. `CoreDisplay_DisplayCreateInfoDictionary` ise sadece bilgi toplama amaçlıdır ve bir yan etki olarak mode pool yenilemesi tetiklememiştir.

---

### Karar:
Live activation deneyleri durdurulmuştur. Sistemde mode pool'u tetikleyecek (106 -> 107 geçişini sağlayacak) bilinen güvenli bir private reload sembolü global namespace'de saptanamamıştır.
