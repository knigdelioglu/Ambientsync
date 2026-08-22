# HiDPI Runtime Trace - Manuel Kullanım Talimatı

1. BetterDisplay kapalıyken veya HiDPI modları aktif değilken AmbientSync diagnostic (veya System Settings) ile Perfect QHD’nin (Logical 2560x1440, Backing 5120x2880) yok olduğunu doğrula.
2. Terminali aç ve proje dizininde şu komutu çalıştır:
   `./scripts/trace_betterdisplay_apply.sh`
3. Script otomatik olarak bir `before` snapshot alacak ve log stream kaydını başlatacak.
4. Ekranda uyarısı görüldüğünde BetterDisplay uygulamasını manuel olarak başlat.
5. Samsung ekranı için BetterDisplay menüsünden "Flexible Scaling" / "Apply" işlemini gerçekleştir.
6. Ekranın yenilendiğini ve Perfect QHD modunun başarıyla geldiğini gözünle kontrol et.
7. Terminale geri dön ve **Enter** tuşuna bas.
8. Script otomatik olarak log akışını durdurup `after` snapshot alacak ve diff raporunu üretecek.
9. Sonuçları `docs/generated/private_activation/runtime_trace/runtime_trace_report.md` dosyasından inceleyebiliriz.
