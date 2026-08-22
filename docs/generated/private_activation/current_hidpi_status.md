# Current HiDPI Status

- Override doğru: Evet. Sistem override ve iki yedek aynı SHA256 ile doğrulandı: `127e69ab6970328c605de85b85f04769febe47077518a2befc4a2273f42000a6`.
- BetterDisplay yokken Perfect QHD mode pool'da var mı: Hayır. `duplicateLowResolutionModes=true` havuzunda 106 mod / 48 HiDPI mod görülüyor.
- Public activation sonucu: Başarısız. Soft refresh, 100Hz -> 60Hz -> 100Hz toggle, CoreGraphics display configuration transaction ve arrangement no-op Perfect QHD üretmedi.
- CGSConfigureDisplayMode sonucu: Başarısız. Result `1001`; Perfect QHD üretmedi. Activation adayı değil.
- SLSDetectDisplays sonucu: Başarısız. `SLSMainConnectionID` başarılı, `SLSDetectDisplays` result `0`, mode count `106 -> 106`; Perfect QHD üretmedi.
- Kalan eksik parça: BetterDisplay'in WindowServer/CoreDisplay runtime mode pool'u `106 -> 107` yaptıran tetikleyicisi.
- Bundan sonra denenmeyecekler: `CGSConfigureDisplayMode`, `CGDisplaySetDisplayMode`, public no-op transaction, SLSDetectDisplays tek başına, listede olmayan elle üretilmiş mod apply/set.
- Bundan sonra tek hedef: BetterDisplay'in `106 -> 107` tetikleyicisini bulmak.
