import SwiftUI
import Foundation

public enum ModuleCategory: String, CaseIterable, Identifiable, Codable {
    case aiAndFiles = "AI & Dosya Araçları"
    case notchAndDock = "Dinamik Ada & Dock"
    case hardwareAndSystem = "Donanım & Sistem (Stats)"
    case productivityAndFix = "Üretkenlik & Sorun Çözücüler"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .aiAndFiles: return "sparkles.rectangle.stack.fill"
        case .notchAndDock: return "menubar.dock.rectangle"
        case .hardwareAndSystem: return "cpu.fill"
        case .productivityAndFix: return "wrench.and.screwdriver.fill"
        }
    }
}

public enum ModuleID: String, CaseIterable, Identifiable, Codable {
    case eneyAI = "01_eney_ai"
    case aiFileOrganizer = "02_ai_file_organizer"
    case nashiToolkit = "03_nashi_toolkit"
    case statsMonitor = "04_stats_monitor"
    case mouseFix = "05_mouse_fix"
    case dynamicIsland = "06_dynamic_island"
    case dockWidgets = "07_dock_widgets"
    case faceIDVision = "08_face_id_vision"
    case menuBarManager = "09_menubar_manager"
    case batteryGuard = "10_battery_guard"
    case audioMixer = "11_audio_mixer"
    case clipboardVault = "12_clipboard_vault"
    case windowLoop = "13_window_loop"
    case cleanShield = "14_clean_shield"
    case monitorDDC = "15_monitor_ddc"
    case appUninstaller = "16_app_uninstaller"
    case screenOCRTools = "17_screen_ocr_tools"
    case keepAwake = "18_keep_awake"
    case mediaOptimizer = "19_media_optimizer"
    case presenterTools = "20_presenter_tools"
    case voiceDictation = "21_voice_dictation"

    public var id: String { rawValue }
}

public struct ModuleDescriptor: Identifiable, Hashable {
    public let id: ModuleID
    public let number: Int
    public let title: String
    public let subtitle: String
    public let category: ModuleCategory
    public let icon: String
    public let accentColor: Color
    public let openSourceBase: String
    public let license: String
    public let shortcutHint: String

    public static let all: [ModuleDescriptor] = [
        ModuleDescriptor(
            id: .eneyAI,
            number: 1,
            title: "Eney Proaktif AI & Wand",
            subtitle: "Ekran/Uygulama okuyan OS ajanı, Takvim/Notlar MCP köprüsü ve Option+W Wand çubuğu",
            category: .aiAndFiles,
            icon: "wand.and.stars",
            accentColor: .purple,
            openSourceBase: "PikoChan + AXorcist + Tinycast + Apple-MCP",
            license: "MIT",
            shortcutHint: "⌥ + W"
        ),
        ModuleDescriptor(
            id: .aiFileOrganizer,
            number: 2,
            title: "AI Dosya Düzenleyici",
            subtitle: "Magika + Vision OCR + Yerel LLM ile İndirilenler/Masaüstü sınıflandırma, Dry-Run & Undo",
            category: .aiAndFiles,
            icon: "folder.fill.badge.gearshape",
            accentColor: .indigo,
            openSourceBase: "ai-file-sorter + Google Magika + LlamaFS",
            license: "MIT / Apache-2.0",
            shortcutHint: "⌘ + ⇧ + O"
        ),
        ModuleDescriptor(
            id: .nashiToolkit,
            number: 3,
            title: "Nashi File Toolkit",
            subtitle: "Sürükle-bırak format dönüştürücü, Vision arka plan silici (Remove BG), QR ve Web indirici",
            category: .aiAndFiles,
            icon: "shippingbox.and.arrow.backward.fill",
            accentColor: .orange,
            openSourceBase: "orkunisitmak/nashi-app",
            license: "Open Source (Swift)",
            shortcutHint: "Notch Drop"
        ),
        ModuleDescriptor(
            id: .statsMonitor,
            number: 4,
            title: "Stats Sistem Monitörü",
            subtitle: "Gerçek zamanlı CPU, RAM, Disk, Ağ, Pil telemetrisi ve Akıllı Süreç Dondurucu (SIGSTOP)",
            category: .hardwareAndSystem,
            icon: "chart.xyaxis.line",
            accentColor: .cyan,
            openSourceBase: "exelban/stats",
            license: "MIT",
            shortcutHint: "Canlı Telemetri"
        ),
        ModuleDescriptor(
            id: .mouseFix,
            number: 5,
            title: "Mouse Fix & Smooth Scroll",
            subtitle: "Harici mouse için bağımsız kaydırma yönü, 120Hz yay fizikli kaydırma, ivme iptali ve yan tuşlar",
            category: .hardwareAndSystem,
            icon: "computermouse.fill",
            accentColor: .blue,
            openSourceBase: "LinearMouse + Mos + Mac Mouse Fix",
            license: "MIT",
            shortcutHint: "Mouse 4/5"
        ),
        ModuleDescriptor(
            id: .dynamicIsland,
            number: 6,
            title: "Dinamik Ada (Notch Hub)",
            subtitle: "MacBook çentiğinde müzik dalgası, dosya rafı (Shelf), Eney AI, Face ID ve HUD değiştirici",
            category: .notchAndDock,
            icon: "rectangle.topthird.inset.filled",
            accentColor: .pink,
            openSourceBase: "BoringNotch + PikoChan",
            license: "Open Source",
            shortcutHint: "Üst Çentik Hover"
        ),
        ModuleDescriptor(
            id: .dockWidgets,
            number: 7,
            title: "Dock Widgets & Previews",
            subtitle: "Dock kenarında canlı sistem/medya widget'ları ve açık pencere önizleme listesi",
            category: .notchAndDock,
            icon: "dock.rectangle",
            accentColor: .teal,
            openSourceBase: "DockDoor + ExtraDock",
            license: "Open Source",
            shortcutHint: "Dock Yanı"
        ),
        ModuleDescriptor(
            id: .faceIDVision,
            number: 8,
            title: "Face ID & Bakış Güvenliği",
            subtitle: "Kamera ile yüz tanıma, göz kırpma canlılık testi, uygulama kilidi ve omuz sörfü koruması",
            category: .notchAndDock,
            icon: "faceid",
            accentColor: .green,
            openSourceBase: "Glance + FaceGate (Apple Vision)",
            license: "MIT",
            shortcutHint: "Biometric Guard"
        ),
        ModuleDescriptor(
            id: .menuBarManager,
            number: 9,
            title: "Menu Bar Yöneticisi (Ice Bar)",
            subtitle: "Çentik arkasında kaybolan menü çubuğu ikonlarını yüzen şık bir çekmecede toplar",
            category: .notchAndDock,
            icon: "menubar.arrow.up.rectangle",
            accentColor: .mint,
            openSourceBase: "jordanbaird/Ice",
            license: "Open Source",
            shortcutHint: "⌥ + M"
        ),
        ModuleDescriptor(
            id: .batteryGuard,
            number: 10,
            title: "Pil Şarj Limitleyici (%80 Guard)",
            subtitle: "Pil sağlığını korumak için %80 şarj tavanı, termal izleme ve tek tıkla %100 Doldur modu",
            category: .hardwareAndSystem,
            icon: "battery.75percent",
            accentColor: .green,
            openSourceBase: "rurza/BatFi + exelban/stats SMC",
            license: "MIT",
            shortcutHint: "%80 Limit"
        ),
        ModuleDescriptor(
            id: .audioMixer,
            number: 11,
            title: "Ses Mikseri & Yönlendirici",
            subtitle: "Uygulama bazlı ses kontrolü, giriş/çıkış cihazı değiştirici ve hızlı EQ profilleri",
            category: .hardwareAndSystem,
            icon: "slider.vertical.3",
            accentColor: .purple,
            openSourceBase: "ronitsingh10/FineTune (CoreAudio)",
            license: "Open Source",
            shortcutHint: "CoreAudio"
        ),
        ModuleDescriptor(
            id: .clipboardVault,
            number: 12,
            title: "Akıllı Pano Kasası (Maccy)",
            subtitle: "Kopyalanan metin, link, renk ve görsellerin geçmişi; şifre filtreli ve OCR destekli",
            category: .productivityAndFix,
            icon: "doc.on.clipboard.fill",
            accentColor: .yellow,
            openSourceBase: "p0deje/Maccy",
            license: "MIT",
            shortcutHint: "⌘ + ⇧ + V"
        ),
        ModuleDescriptor(
            id: .windowLoop,
            number: 13,
            title: "Window Loop & Snap",
            subtitle: "Aktif pencereyi tek tıkla veya kısayolla Sol/Sağ Yarıya, Çeyreklere veya Merkeze hizalar",
            category: .productivityAndFix,
            icon: "macwindow.split.2x1",
            accentColor: .blue,
            openSourceBase: "rxhanson/Rectangle + MrKai77/Loop",
            license: "MIT",
            shortcutHint: "⌃ + ⌥ + Yön"
        ),
        ModuleDescriptor(
            id: .cleanShield,
            number: 14,
            title: "Klavye & Ekran Temizlik Kilidi",
            subtitle: "MacBook klavyesini ve ekranını bezle silerken 60 saniye tüm tuş ve tıklamaları kilitler",
            category: .productivityAndFix,
            icon: "keyboard.badge.ellipsis",
            accentColor: .red,
            openSourceBase: "CleanKey (CGEventTap Shield)",
            license: "MIT",
            shortcutHint: "60sn Kilit"
        ),
        ModuleDescriptor(
            id: .monitorDDC,
            number: 15,
            title: "Harici Monitör Parlaklık (DDC)",
            subtitle: "Harici ekranlar için donanım/yazılım parlaklık kısma (Dimmer) ve Gece Kalkanı",
            category: .hardwareAndSystem,
            icon: "display.2",
            accentColor: .orange,
            openSourceBase: "MonitorControl/MonitorControl",
            license: "MIT",
            shortcutHint: "F1 / F2"
        ),
        ModuleDescriptor(
            id: .appUninstaller,
            number: 16,
            title: "Hayalet Kalıntı Temizleyici",
            subtitle: "~/Library/Caches, Application Support ve Preferences altındaki yetim uygulama çöplerini bulur",
            category: .productivityAndFix,
            icon: "trash.slash.fill",
            accentColor: .pink,
            openSourceBase: "Alienator88/Pearcleaner",
            license: "Open Source",
            shortcutHint: "Derin Tarama"
        ),
        ModuleDescriptor(
            id: .screenOCRTools,
            number: 17,
            title: "TRex Ekran OCR, Tablo & Renk",
            subtitle: "Ekrandan/videodan metin ve Markdown tablo çıkarma + büyüteçli ekran renk seçici (HEX/SwiftUI)",
            category: .aiAndFiles,
            icon: "text.viewfinder",
            accentColor: .mint,
            openSourceBase: "amebalabs/TRex",
            license: "MIT",
            shortcutHint: "⌘ + ⇧ + 2"
        ),
        ModuleDescriptor(
            id: .keepAwake,
            number: 18,
            title: "Akıllı Uyanık Tutucu (Caffeinate)",
            subtitle: "İndirme, derleme veya AI eğitimi sırasında Mac'in uykuya geçmesini engeller (Pil korumalı)",
            category: .productivityAndFix,
            icon: "cup.and.saucer.fill",
            accentColor: .brown,
            openSourceBase: "newmarcel/KeepingYouAwake",
            license: "MIT",
            shortcutHint: "Caffeinate"
        ),
        ModuleDescriptor(
            id: .mediaOptimizer,
            number: 19,
            title: "Clop Otomatik Görsel Küçültücü",
            subtitle: "Panodaki veya yeni çekilen ekran görüntülerini kalite kaybı olmadan %70'e kadar sıkıştırır",
            category: .aiAndFiles,
            icon: "arrow.down.right.and.arrow.up.left.circle.fill",
            accentColor: .indigo,
            openSourceBase: "FuzzyIdeas/Clop",
            license: "Open Source",
            shortcutHint: "Oto-Sıkıştır"
        ),
        ModuleDescriptor(
            id: .presenterTools,
            number: 20,
            title: "KeyCastr Tuş Gösterici",
            subtitle: "Sunum ve ekran kaydı sırasında basılan klavye tuşlarını ekranda şık bir kapsülde gösterir",
            category: .productivityAndFix,
            icon: "command.square.fill",
            accentColor: .cyan,
            openSourceBase: "keycastr/keycastr",
            license: "BSD-3-Clause",
            shortcutHint: "Canlı Kapsül"
        ),
        ModuleDescriptor(
            id: .voiceDictation,
            number: 21,
            title: "Yerel AI Sesli Dikte (Push-to-Talk)",
            subtitle: "Mikrofondan Türkçe/İngilizce konuşmayı yazıya döker ve Eney AI ile imla/dolgu kelimelerini düzeltir",
            category: .aiAndFiles,
            icon: "waveform.and.mic",
            accentColor: .red,
            openSourceBase: "argmaxinc/WhisperKit + Trace",
            license: "MIT",
            shortcutHint: "Bas-Konuş"
        )
    ]
}
