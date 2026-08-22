# Real Maximum Brightness Diagnostic

## Target display
- Display name: LS32D60xU
- Display ID: unavailable
- Vendor ID: 0x4C2D
- Product ID: 0x76AB
- Serial: 0x30413332
- DDC display index: 2

## DDC brightness current/max before
- Current brightness: 17
- Max brightness: 50

## Set brightness 100 result
- Write success: YES

## DDC brightness readback after
- Readback brightness: 17

## DDC contrast current/max
- Current contrast: 17
- Max contrast: 50

## Supported VCP codes
- MCCS capabilities available: NO
- MCCS capabilities string: unavailable
- Supported VCP codes: 0x10 Brightness, 0x12 Contrast, 0x16 Red Video Gain, 0x18 Green Video Gain, 0x1A Blue Video Gain

## HDR/Eco/Eye Saver suspicion notes
- MCCS capabilities string not available through m1ddc on this system
- Brightness 100 olsa bile contrast düşük olduğu için görüntü sönük algılanabilir.
- DDC brightness max is 50, so UI percentage mapping may need rescaling
- DDC readback value did not move to 100 after the write

## Diagnosis
- DDC brightness max değeri 100 değil; UI yüzde mapping’i yeniden ölçeklenmeli.
- Contrast düşük; brightness 100 olsa bile görüntü sönük algılanabilir.
- Possible brightness limiter: YES

## Recommended manual checks
- DDC brightness UI mapping'ini max 50 üzerinden ölçekle.
- Contrast ayarını yükselt ve tekrar gözle görsel karşılaştırma yap.
- Monitor OSD'de Eco / Eye Saver / Adaptive Picture seçeneklerini kapat.
- HDR / High Dynamic Range modunu kapatıp tekrar test et.
- OS X renk profili ve ICC profilini kontrol et.
- Brightness 100 yazıldıktan sonra readback ile panel parlaklığını karşılaştır.
- Monitörün kendi OSD brightness / contrast değerlerini manuel olarak doğrula.
