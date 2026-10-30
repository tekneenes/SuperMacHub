# SuperMacHub — All-in-One Native macOS AI Companion & System Utility Suite

Mac kullanıcılarının 20+ ayrı ücretli/açık kaynak uygulamaya ihtiyaç duyduğu tüm özellikleri, **tamamen serbest lisanslı (MIT / Apache 2.0 / BSD) açık kaynak çekirdekleri** birleştirerek tek bir modüler **Swift / SwiftUI + Apple MLX / Vision** çatısı altında toplayan süper uygulama projesi.

## Eney AI ve Modüller İçin Kullanılan Açık Kaynak Çekirdekler (`Vendor/`)

Sıfırdan yazmak yerine doğrudan entegre edeceğimiz/özelleştireceğimiz serbest lisanslı açık kaynak projeler:

| Modül | Temel Alınacak Açık Kaynak Proje (GitHub) | Lisans | Ne Sağlıyor? |
| :--- | :--- | :--- | :--- |
| **01. Eney AI (Notch & Hands)** | `neur0map/PikoChan` + `abue-ammar/tinycast` | Açık Kaynak / MIT | Çentik içi AI asistanı, Ollama/Cloud bağlantısı, `Option+W` hızlı aksiyon çubuğu ve komut çalıştırma ("Hands") |
| **01. Eney Gözü (UI & Ekran)** | `steipete/AXorcist` + `NivDvir/screen-overlay-toolkit` + `AnthonyDavidAdams/Lookout` | MIT | Ekrandaki açık uygulamaların buton/metin ağacını (`AXUIElement`) okuma, `ScreenCaptureKit` ile ekranı görme ve ekrana işaretçi çizme |
| **01. Eney Uygulama Köprüsü** | `AaronRoeF/apple-mcp` + `FradSer/mcp-server-apple-events` | MIT | Apple Mail, Takvim, Anımsatıcılar, Notlar, Rehber ve Safari'yi okuyan/yazan 28+ hazır yerel araç (`EventKit` & JXA) |
| **02. AI Dosya Düzenleyici** | `hyperfield/ai-file-sorter` + `google/magika` | MIT / Apache-2.0 | İçerik okuyan yerel LLM/Vision dosya sınıflandırıcı, Dry-Run önizleme ve Undo (Geri Alma) |
| **03. Nashi File Toolkit** | `orkunisitmak/nashi-app` | Açık Kaynak | Medya/dosya dönüştürme, web video indirme, QR okuma ve düzenleme iş akışları |
| **04. Sistem Monitörü** | `exelban/stats` | MIT | CPU, GPU, RAM, Disk, Ağ, Fan, Pil ve Bluetooth donanım telemetrisi (`SMC` & `SystemKit`) |
| **05. Mouse Fix** | `linearmouse/linearmouse` + `caldis/Mos` | MIT / Açık Kaynak | Smooth scrolling, bağımsız mouse/trackpad yönü, ivme iptali ve yan tuş atamaları |
| **06. Dinamik Ada (Notch)** | `TheBoringNotch/boring.notch` / `PikoChan` | Açık Kaynak | İnteraktif çentik, müzik dalgası, dosya rafı (Shelf) ve ses/parlaklık HUD değiştirici |
| **08. Face ID & Kamera** | `tryglance` / `FaceGate` (`Vision` + `MobileFaceNet`) | Açık Kaynak | Yüz vektörü ile ekran/uygulama kilidi açma, göz kırpma canlılık kontrolü ve omuz sörfü koruması |
| **09. Menu Bar Yöneticisi** | `jordanbaird/Ice` | GPL/MIT | Çentik arkasında kalan menü çubuğu ikonlarını gizleme ve Ice Bar çekmecesi |
| **10. Pil Şarj Limitleyici** | `rurza/BatFi` + `exelban/stats (SMC)` | Açık Kaynak / MIT | Pil şarjını %80'de sabitleme ve termal koruma |
| **11. Ses Mikseri** | `ronitsingh10/FineTune` | Açık Kaynak | `CoreAudio Tap` ile sürücüsüz uygulama bazlı ses seviyesi ve çıkış cihazı yönlendirme |
| **12. Akıllı Pano & OCR** | `p0deje/Maccy` + `amebalabs/TRex` | MIT | Pano geçmişi, ekrandan/videodan OCR ile metin ve Markdown tablo yakalama |
| **13. Pencere Yöneticisi** | `rxhanson/Rectangle` / `MrKai77/Loop` | MIT | Kısayol veya dairesel menü ile pencere bölme/hizalama |
| **15. Harici Monitör DDC** | `MonitorControl/MonitorControl` | MIT | Harici monitör parlaklık ve sesini klavyeden kontrol etme |
| **18. Uyanık Tutucu** | `newmarcel/KeepingYouAwake` | MIT | İndirme/AI eğitimi sırasında Mac'in uykuya geçmesini engelleme |
| **21. Sesli Dikte (Voice AI)** | `argmaxinc/WhisperKit` + `arjunkomath/trace` | MIT | Tuşa basılı tutarak (Push-to-Talk) her uygulamada yerel AI ile konuşmayı yazıya dökme |
