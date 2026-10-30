# SuperMacHub 
### All-in-One Native macOS AI Companion & Modular System Utility Suite

[![Swift](https://img.shields.io/badge/Swift-5.10%2B-FA7343?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org/)
[![macOS](https://img.shields.io/badge/macOS-14.0%2B%20Sonoma%20%7C%20Sequoia-000000?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Apple Silicon](https://img.shields.io/badge/Architecture-Apple%20Silicon%20(M1--M4)-0071e3?style=for-the-badge)](https://developer.apple.com/silicon/)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=for-the-badge)](LICENSE)
[![Local AI](https://img.shields.io/badge/AI%20Engine-Apple%20MLX%20%2F%20Vision-FF2D55?style=for-the-badge)](https://github.com/ml-explore/mlx)

> **20+ ayrı ücretli ve dağınık macOS yardımcı uygulamasını tek bir çatıda birleştiren; yerel Apple MLX, Vision ve SwiftUI ile inşa edilmiş fütüristik süper uygulama ekosistemi.**

---

## 🌟 Neden SuperMacHub?

Modern bir Mac kullanıcısı günlük iş akışında genellikle 10 ila 20 farklı arka plan aracı çalıştırmak zorunda kalır *(Stats, LinearMouse, BoringNotch, Rectangle, Maccy, BatFi, MonitorControl, KeepingYouAwake, Ice vb.)*. Bu durum bellek şişmesine, uyumsuz izin yönetimlerine ve pil tüketimine yol açar.

**SuperMacHub**, serbest lisanslı (MIT / Apache-2.0 / BSD) açık kaynak çekirdeklerini homojen bir mimaride birleştirir. Sıfır sürücü gereksinimiyle doğrudan **Apple Silicon (M1-M4), macOS Sonoma & Sequoia ve Liquid Glass SwiftUI** tasarım dili için optimize edilmiştir.

---

## 🏛️ Mimari ve Sistem Tasarımı

```
┌────────────────────────────────────────────────────────────────────────┐
│                   SuperMacHub Liquid Glass UI Layer                   │
│   (Bento Kontrol Merkezi • Dinamik Ada Stüdyosu • Menü Çubuğu Açılırı)   │
└────────────────────────────────────┬───────────────────────────────────┘
                                     │
┌────────────────────────────────────┴───────────────────────────────────┐
│                    Modüler Hub Çekirdeği (Swift 5.10)                  │
├─────────────────────┬─────────────────────┬────────────────────────────┤
│   🤖 AI & Vision    │   ⚡ Donanım & SMC   │   🪟 Pencere & Giriş      │
│  - Eney AI (⌥+W)    │  - CPU/GPU/RAM Tele │  - Linear Mouse Fix        │
│  - MLX LoRA Hattı   │  - SMC Pil %80 Lim  │  - Window Loop / Snap      │
│  - Vision Face ID   │  - CoreAudio Tap    │  - Ice Menü Çubuğu         │
│  - Google Magika    │  - DDC Ekran Monit. │  - Akıllı Pano & OCR       │
└─────────────────────┴─────────────────────┴────────────────────────────┘
                                     │
┌────────────────────────────────────┴───────────────────────────────────┐
│                 Yerel macOS Çerçeveleri & Sistem API'leri              │
│   (ScreenCaptureKit • AXUIElement • EventKit • SMC • Vision • MLX)     │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🍱 21 Modül ve Entegre Sistem Özellikleri

### 1. 🤖 Yapay Zeka, Görsel & Dosya Zekası
| Modül | Kısayol / Erişim | Açıklama |
| :--- | :--- | :--- |
| **01. Eney AI Agent & Hands** | `Option + W` | Çentik içi asistan; ekrandaki buton ve metin ağacını okuyan (`AXUIElement`), `ScreenCaptureKit` ile ekranı gören ve yerel araçları çalıştıran yapay zeka ajanı. |
| **01. Apple MCP Köprüsü** | Arka Plan | Mail, Takvim, Notlar, Anımsatıcılar, Rehber ve Safari'yi okuyan/yazan 28+ hazır yerel araç köprüsü (`EventKit` & JXA). |
| **02. AI Dosya Düzenleyici** | Dashboard | Yerel LLM/Vision ve Google Magika ile dosya içeriklerini okuyarak akıllı sınıflandıran, Dry-Run ve tek tıkla geri alma (Undo) destekli dosya düzenleyici. |
| **03. Nashi File Toolkit** | Dashboard | Medya dönüştürme, tek tıkla video indirme, QR okuyucu ve hızlı dosya işleme araç takımı. |
| **08. Face ID Vision & Glance** | WebCam | Vision framework ile yüz biyometrisi doğrulama; göz kırpma canlılık testi ve omuz sörfü (arkadan bakanları tespit) koruması. |
| **21. WhisperKit Sesli Dikte** | Bas-Konuş | Tuşa basılı tutarak herhangi bir metin alanında tamamen cihaz içinde çalışan yerel AI sesli dikte motoru. |

### 2. ⚡ Donanım, Güç & Ses Telemetrisi
| Modül | Çekirdek | Açıklama |
| :--- | :--- | :--- |
| **04. Stats Sistem Monitörü** | SMC & SystemKit | Menü çubuğunda canlı CPU, GPU, RAM, Disk I/O, Ağ trafiği, Fan hızı ve Bluetooth cihaz pil telemetrisi. |
| **10. Battery Guard** | SMC Driver | Batarya ömrünü uzatmak için şarjı %80 eşiğinde sabitleyen ve termal koruma sağlayan akıllı güç yöneticisi. |
| **11. Sürücüsüz Ses Mikseri** | `CoreAudio Tap` | KEXT veya harici ses sürücüsü kurmadan, uygulama bazında bağımsız ses seviyesi ayarlama ve çıkış cihazı yönlendirme. |
| **15. Harici Monitör DDC** | DDC/CI Protocol | Harici monitörlerin parlaklık ve sesini doğrudan Apple klavye tuşlarıyla kontrol etme. |
| **18. Uyanık Tutucu (Caffeine)** | IOPMAssertion | Büyük indirmeler, render veya AI eğitimi sırasında ekranın ve sistemin uykuya geçmesini önleme. |

### 3. 🖱️ Giriş Birimleri, Pencereler & Masaüstü Üretkenliği
| Modül | Çekirdek | Açıklama |
| :--- | :--- | :--- |
| **05. Mouse Fix & Mos** | Quartz Event Tap | Harici farelerde bağımsız kaydırma yönü, pürüzsüz ivme düzeltme (smooth scrolling) ve yan tuş özelleştirme. |
| **06. Dinamik Ada Stüdyosu** | Floating Overlay | MacBook çentiğini interaktif bir bilgi merkezine dönüştürür; müzik dalga formu, geçici dosya rafı (Shelf) ve HUD göstergeleri. |
| **09. Menü Çubuğu Yöneticisi** | Window Server | Çentik arkasında kaybolan menü ikonlarını gizleyen, tıklamayla açılan Ice Bar çekmecesi. |
| **12. Akıllı Pano & Tablo OCR** | AppKit & Vision | Pano geçmişi, ekrandan/videodan tek tuşla metin ve Markdown formatında veri tablosu kopyalama. |
| **13. Window Loop & Tiling** | Accessibility API | Kısayollar ve dairesel radyal menü ile pencereleri ekranda 1/2, 1/3, 1/4 oranlarında bölme ve hizalama. |
| **14. CleanShield Sistem Temizliği** | Yerel Dosya Motoru | Xcode DerivedData, SPM önbellekleri, loglar ve sistem artıklarını tek tıkla güvenli temizleme. |
| **16. Akıllı Uygulama Kaldırıcı** | FS Watcher | Bir `.app` silindiğinde `~/Library` altındaki gizli artık dosyaları tespit edip tamamen yok etme. |
| **19. Medya Optimize Edici** | AVFoundation | Görsel ve videoları kalite kaybı olmadan WebP, AVIF veya H.265 formatına sıkıştırma. |
| **20. Sunum Araçları** | Screen Overlay | Canlı sunumlarda ekranda lazer işaretçi gösterme ve klavye kısayollarını ekrana basma (Keystroke OSD). |

---

## 🧠 Yerel Apple MLX LoRA Eğitim Hattı

SuperMacHub, macOS içinde çalışan yerel modelleri kişiselleştirmek için `AIModels/TrainingPipeline/` altında yerleşik bir eğitim ortamı sunar:
- **`prepare_dataset.py`:** macOS aksiyonlarını ve kullanıcı komutlarını MLX uyumlu JSONL formatına dönüştürür.
- **`train_mlx_lora.sh`:** Apple Silicon Neural Engine & Metal Unified Memory üzerinde 4-bit LoRA eğitimi gerçekleştirir.
- **`Modelfile`:** Eğitilen adaptörleri yerel Ollama / MLX sunucularına aktarır.

---

## 🛠️ Kurulum ve Derleme (Build from Source)

### Gereksinimler
- **İşletim Sistemi:** macOS 14.0 (Sonoma) veya macOS 15.0+ (Sequoia)
- **Mimari:** Apple Silicon (M1 / M2 / M3 / M4)
- **Geliştirme Araçları:** Xcode 15.3+ veya Swift 5.10+ CLI

### Adım Adım Derleme

```bash
# Repoyu klonlayın
git clone https://github.com/tekneenes/SuperMacHub.git
cd SuperMacHub

# SPM ile bağımlılıkları çözün ve derleyin
swift build -c release

# Uygulamayı başlatın
swift run SuperMacHub
```

### Xcode ile Çalıştırma
Projeyi doğrudan Xcode'da açmak için `Package.swift` dosyasını Xcode ile açmanız ve `SuperMacHub` hedefini seçip **⌘ + R** tuşlarına basmanız yeterlidir.

---

## 🔑 Gerekli Sistem İzinleri

SuperMacHub'ın sistem düzeyindeki özellikleri eksiksiz çalıştırabilmesi için macOS Güvenlik ve Gizlilik panelinden aşağıdaki izinler talep edilir:
- **Erişilebilirlik (Accessibility):** Pencere yönetimi ve fare düzeltici için.
- **Ekran Kaydı (Screen Recording):** Eney Vision ve ekran OCR analizleri için.
- **Otomasyon (Apple Events):** Apple MCP köprüsü (Mail, Takvim, Notlar) için.
- **Mikrofon:** Bas-Konuş yerel WhisperKit sesli dikte için.

---

## 📜 Lisans & Açık Kaynak Atıfları

Bu proje **[Apache License 2.0](LICENSE)** altında lisanslanmıştır.

SuperMacHub; bağımsız açık kaynak topluluğunun geliştirdiği serbest lisanslı (MIT, Apache 2.0, BSD) harika çekirdeklerden ilham almış ve bu projeleri tek bir çatı altında birleştirmiştir. Tüm orijinal kütüphaneler, lisansları ve telif hakları **[NOTICE](NOTICE)** dosyasında ayrıntılı olarak belgelenmiş ve atıfta bulunulmuştur.

---

## 👨‍💻 Geliştirici & İletişim

**Muhammed Enes Tekne**  
- **GitHub:** [@tekneenes](https://github.com/tekneenes)  
- **LinkedIn:** [Muhammed Enes Tekne](https://www.linkedin.com/in/muhammed-enes-tekne)  
- **Portfolyo:** [tekneenes.github.io](https://tekneenes.github.io)
