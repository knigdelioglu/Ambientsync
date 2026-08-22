# CGS Mode 74 Apply Experiment

Generated at: 2026-05-20T18:23:38Z

## Before mode id
- 74

## Mode 56 doğrulandı mı?
- Evet

## Mode 74 doğrulandı mı?
- Evet

## Mode 56 apply sonucu
- requested 56 | before 74 | after 74 | apply attempted | CGSConfigureDisplayMode(56) + CGCompleteDisplayConfiguration(option: 2) succeeded. | rollback: CGSConfigureDisplayMode(74) + CGCompleteDisplayConfiguration(option: 2) succeeded. | failure

## Mode 74 apply sonucu
- requested 74 | before 74 | after 74 | already active | Mode 74 Perfect QHD zaten aktif; apply atlandı. | success

## Final active mode
- 2560x1440 logical / 5120x2880 pixel @ 100.00Hz / ioMode 74

## system_profiler sonucu
```
      Vendor: Apple (0x106b)
          Resolution: 2560 x 1664 Retina
          Resolution: 5120 x 2880 (5K/UHD+ - Ultra High Definition Plus)
          UI Looks like: 2560 x 1440 @ 100.00Hz
```

## Başarı/başarısızlık
- Başarılı
