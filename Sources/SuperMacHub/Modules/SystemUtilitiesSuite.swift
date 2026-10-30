import Foundation
import AppKit
import SwiftUI
import ApplicationServices
import CoreAudio
import Vision
import Speech

// MARK: - Module 07: Dock Widgets & Window Previews (DockDoor + ExtraDock)
public struct OpenWindowPreviewItem: Identifiable, Hashable {
    public let id: Int
    public let ownerName: String
    public let windowTitle: String
    public let boundsDescription: String
}

@MainActor
public final class DockWidgetsManager: ObservableObject {
    public static let shared = DockWidgetsManager()

    @Published public var isDockWidgetVisible: Bool = false
    @Published public var openWindows: [OpenWindowPreviewItem] = []

    private var dockPanel: NSPanel?

    private init() {
        refreshOpenWindows()
    }

    public func refreshOpenWindows() {
        guard let infoList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return
        }
        var items: [OpenWindowPreviewItem] = []
        for info in infoList {
            let layer = info[kCGWindowLayer as String] as? Int ?? 0
            guard layer == 0,
                  let owner = info[kCGWindowOwnerName as String] as? String,
                  let wid = info[kCGWindowNumber as String] as? Int else { continue }
            let title = (info[kCGWindowName as String] as? String) ?? owner
            items.append(OpenWindowPreviewItem(id: wid, ownerName: owner, windowTitle: title.isEmpty ? owner : title, boundsDescription: "Pencere #\(wid)"))
        }
        openWindows = Array(items.prefix(16))
    }

    public func toggleFloatingDockWidget() {
        if dockPanel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 24, y: 24, width: 320, height: 96),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.contentView = NSHostingView(rootView: FloatingDockWidgetView())
            dockPanel = panel
        }

        if isDockWidgetVisible {
            dockPanel?.orderOut(nil)
            isDockWidgetVisible = false
        } else {
            dockPanel?.orderFrontRegardless()
            isDockWidgetVisible = true
        }
    }
}

public struct FloatingDockWidgetView: View {
    @ObservedObject var stats = StatsEngine.shared

    public var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ExtraDock Canlı Widget")
                    .font(.caption.bold())
                    .foregroundStyle(.teal)
                Text("CPU %\(Int(stats.cpuUsagePercent)) • RAM %\(Int(stats.memoryPressurePercent))")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.white)
                Text("Boş Disk: \(String(format: "%.0f", stats.diskFreeGB)) GB • Pil: %\(stats.batteryPercent)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))
            }
            Spacer()
            Button("İndirilenleri Düzenle") {
                AIFileOrganizerManager.shared.scanFolder()
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            .controlSize(.small)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.teal.opacity(0.6), lineWidth: 1.2)
                )
        )
    }
}

// MARK: - Module 12: Clipboard Vault (Maccy Style Live Pasteboard + OCR)
public struct ClipboardEntry: Identifiable, Hashable {
    public let id = UUID()
    public let content: String
    public let timestamp: Date
    public var isPinned: Bool
}

@MainActor
public final class ClipboardVaultManager: ObservableObject {
    public static let shared = ClipboardVaultManager()

    @Published public var entries: [ClipboardEntry] = []
    @Published public var searchQuery: String = ""
    @Published public var ignorePasswords: Bool = true

    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var timer: Timer?

    private init() {
        if let initial = NSPasteboard.general.string(forType: .string), !initial.isEmpty {
            entries.append(ClipboardEntry(content: initial, timestamp: Date(), isPinned: false))
        }
        startPolling()
    }

    public func startPolling() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPasteboard()
            }
        }
    }

    private func checkPasteboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        // Ignore password manager concealed types
        if ignorePasswords,
           let types = pb.types,
           types.contains(where: { $0.rawValue.lowercased().contains("concealed") || $0.rawValue.lowercased().contains("password") }) {
            return
        }

        if let str = pb.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !str.isEmpty,
           entries.first?.content != str {
            entries.insert(ClipboardEntry(content: str, timestamp: Date(), isPinned: false), at: 0)
            if entries.count > 100 { entries.removeLast() }
        }
    }

    public func copyToPasteboard(_ entry: ClipboardEntry) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entry.content, forType: .string)
        lastChangeCount = NSPasteboard.general.changeCount
    }
}

// MARK: - Module 13: Window Loop & Snap (Rectangle + Loop Style)
public enum WindowSnapPosition: String, CaseIterable, Identifiable {
    case leftHalf = "Sol Yarı (%50)"
    case rightHalf = "Sağ Yarı (%50)"
    case topHalf = "Üst Yarı"
    case bottomHalf = "Alt Yarı"
    case maximize = "Tam Ekran (Maximize)"
    case center80 = "Merkez Odak (%80)"

    public var id: String { rawValue }
    public var icon: String {
        switch self {
        case .leftHalf: return "rectangle.lefthalf.filled"
        case .rightHalf: return "rectangle.righthalf.filled"
        case .topHalf: return "rectangle.tophalf.filled"
        case .bottomHalf: return "rectangle.bottomhalf.filled"
        case .maximize: return "arrow.up.left.and.arrow.down.right"
        case .center80: return "macwindow"
        }
    }
}

@MainActor
public final class WindowLoopManager: ObservableObject {
    public static let shared = WindowLoopManager()
    @Published public var statusMessage: String = "Aktif pencereyi hizalamak için bir düzen seçin."

    private init() {}

    public func snapFocusedWindow(to position: WindowSnapPosition) {
        guard AXIsProcessTrusted() else {
            PermissionsManager.shared.requestAccessibility()
            statusMessage = "⚠️ Pencere boyutlandırma için Accessibility izni gerekiyor."
            return
        }
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame

        var targetRect = visible
        switch position {
        case .leftHalf:
            targetRect = NSRect(x: visible.minX, y: visible.minY, width: visible.width / 2, height: visible.height)
        case .rightHalf:
            targetRect = NSRect(x: visible.midX, y: visible.minY, width: visible.width / 2, height: visible.height)
        case .topHalf:
            targetRect = NSRect(x: visible.minX, y: visible.midY, width: visible.width, height: visible.height / 2)
        case .bottomHalf:
            targetRect = NSRect(x: visible.minX, y: visible.minY, width: visible.width, height: visible.height / 2)
        case .maximize:
            targetRect = visible
        case .center80:
            let w = visible.width * 0.8
            let h = visible.height * 0.8
            targetRect = NSRect(x: visible.midX - w / 2, y: visible.midY - h / 2, width: w, height: h)
        }

        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        let appEl = AXUIElementCreateApplication(frontApp.processIdentifier)
        var winRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appEl, kAXFocusedWindowAttribute as CFString, &winRef) == .success,
           let win = winRef {
            var pt = CGPoint(x: targetRect.origin.x, y: screen.frame.maxY - targetRect.maxY)
            var sz = CGSize(width: targetRect.width, height: targetRect.height)
            if let posVal = AXValueCreate(.cgPoint, &pt),
               let sizeVal = AXValueCreate(.cgSize, &sz) {
                AXUIElementSetAttributeValue(win as! AXUIElement, kAXPositionAttribute as CFString, posVal)
                AXUIElementSetAttributeValue(win as! AXUIElement, kAXSizeAttribute as CFString, sizeVal)
                statusMessage = "✅ \(frontApp.localizedName ?? "Pencere") -> \(position.rawValue) hizalandı."
            }
        }
    }
}

// MARK: - Module 14, 16, 17, 18, 19, 20, 21 Combined Utility Controller
public struct LeftoverCacheItem: Identifiable, Hashable {
    public let id = UUID()
    public let name: String
    public let path: String
    public let sizeMB: Double
}

@MainActor
public final class SystemUtilitiesManager: ObservableObject {
    public static let shared = SystemUtilitiesManager()

    // Module 10: Battery Guard
    @Published public var chargeLimitPercent: Double = 80.0
    @Published public var pauseOnHighTemp: Bool = true

    // Module 14: CleanShield (Keyboard Lock)
    @Published public var isCleanShieldActive: Bool = false
    @Published public var cleanShieldSecondsRemaining: Int = 0
    private var cleanTimer: Timer?

    // Module 16: AppUninstaller / Leftover Cache Scanner
    @Published public var discoveredCaches: [LeftoverCacheItem] = []
    @Published public var totalCacheMB: Double = 0.0

    // Module 17: TRex OCR & Color Picker
    @Published public var pickedHexColor: String = "#7C3AED"
    @Published public var pickedSwiftUIColor: String = "Color(red: 0.49, green: 0.23, blue: 0.93)"
    @Published public var extractedMarkdownTable: String = ""

    // Module 18: KeepAwake (Caffeinate)
    @Published public var isKeepAwakeActive: Bool = false
    private var caffeinateProcess: Process?

    // Module 20: KeyCastr Presenter Overlay
    @Published public var isKeyCastrActive: Bool = false
    @Published public var lastKeystrokeDisplay: String = "⌘ + ⇧ + P"
    private var keyMonitor: Any?

    // Module 21: Voice Dictation
    @Published public var dictatedText: String = ""
    @Published public var isDictating: Bool = false

    private init() {
        scanUserCaches()
    }

    // MARK: - Module 14: Clean Shield 30s Countdown
    public func startCleanShield(seconds: Int = 30) {
        isCleanShieldActive = true
        cleanShieldSecondsRemaining = seconds
        cleanTimer?.invalidate()
        cleanTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            Task { @MainActor in
                guard let self = self else { return }
                if self.cleanShieldSecondsRemaining > 1 {
                    self.cleanShieldSecondsRemaining -= 1
                } else {
                    t.invalidate()
                    self.isCleanShieldActive = false
                }
            }
        }
    }

    public func stopCleanShield() {
        cleanTimer?.invalidate()
        isCleanShieldActive = false
    }

    // MARK: - Module 16: Scan ~/Library/Caches (Pearcleaner style)
    public func scanUserCaches() {
        let cachesURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Caches")
        guard let dirs = try? FileManager.default.contentsOfDirectory(at: cachesURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
            return
        }

        var items: [LeftoverCacheItem] = []
        var sumMB: Double = 0.0

        for dir in dirs.prefix(20) {
            let sizeBytes = Self.directorySize(url: dir)
            let mb = Double(sizeBytes) / (1024.0 * 1024.0)
            if mb >= 0.5 {
                items.append(LeftoverCacheItem(name: dir.lastPathComponent, path: dir.path, sizeMB: mb))
                sumMB += mb
            }
        }
        discoveredCaches = items.sorted { $0.sizeMB > $1.sizeMB }
        totalCacheMB = sumMB
    }

    nonisolated private static func directorySize(url: URL) -> UInt64 {
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else {
            return 0
        }
        var total: UInt64 = 0
        var count = 0
        for case let fileURL as URL in enumerator {
            count += 1
            if count > 250 { break }
            if let sz = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += UInt64(max(0, sz))
            }
        }
        return total
    }

    // MARK: - Module 17: Native Screen Color Sampler & OCR Table Converter
    public func pickScreenColor() {
        NSColorSampler().show { [weak self] selectedColor in
            guard let self = self, let color = selectedColor?.usingColorSpace(.sRGB) else { return }
            let r = Int(color.redComponent * 255)
            let g = Int(color.greenComponent * 255)
            let b = Int(color.blueComponent * 255)
            Task { @MainActor in
                self.pickedHexColor = String(format: "#%02X%02X%02X", r, g, b)
                self.pickedSwiftUIColor = String(
                    format: "Color(red: %.2f, green: %.2f, blue: %.2f)",
                    color.redComponent,
                    color.greenComponent,
                    color.blueComponent
                )
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(self.pickedHexColor, forType: .string)
            }
        }
    }

    public func convertTextToMarkdownTable(_ rawText: String) {
        let lines = rawText.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !lines.isEmpty else {
            extractedMarkdownTable = "| Sütun 1 | Sütun 2 |\n| --- | --- |\n| Veri yok | - |"
            return
        }
        var md: [String] = []
        for (idx, line) in lines.enumerated() {
            let cols = line.components(separatedBy: CharacterSet(charactersIn: "\t,;"))
                .map { $0.trimmingCharacters(in: .whitespaces) }
            md.append("| " + cols.joined(separator: " | ") + " |")
            if idx == 0 {
                md.append("| " + cols.map { _ in "---" }.joined(separator: " | ") + " |")
            }
        }
        extractedMarkdownTable = md.joined(separator: "\n")
    }

    // MARK: - Module 18: KeepAwake (Caffeinate)
    public func toggleKeepAwake() {
        if isKeepAwakeActive {
            caffeinateProcess?.terminate()
            caffeinateProcess = nil
            isKeepAwakeActive = false
        } else {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
            proc.arguments = ["-di"]
            do {
                try proc.run()
                caffeinateProcess = proc
                isKeepAwakeActive = true
            } catch {
                isKeepAwakeActive = false
            }
        }
    }

    // MARK: - Module 20: KeyCastr Keystroke Visualizer
    public func toggleKeyCastr() {
        if isKeyCastrActive {
            if let mon = keyMonitor {
                NSEvent.removeMonitor(mon)
            }
            keyMonitor = nil
            isKeyCastrActive = false
        } else {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                let chars = event.charactersIgnoringModifiers?.uppercased() ?? ""
                var mods: [String] = []
                if event.modifierFlags.contains(.command) { mods.append("⌘") }
                if event.modifierFlags.contains(.shift) { mods.append("⇧") }
                if event.modifierFlags.contains(.option) { mods.append("⌥") }
                if event.modifierFlags.contains(.control) { mods.append("⌃") }
                let combo = (mods + [chars]).filter { !$0.isEmpty }.joined(separator: " + ")
                if !combo.isEmpty {
                    Task { @MainActor in
                        self?.lastKeystrokeDisplay = combo
                    }
                }
                return event
            }
            isKeyCastrActive = true
        }
    }
}
