import Foundation
import AppKit
import SwiftUI
import ApplicationServices
import EventKit
import NaturalLanguage
import Vision
@preconcurrency import ScreenCaptureKit

// MARK: - 1. Key-Capable Floating Panel for Eney AI Spotlight Overlay
public final class EneySpotlightFloatingPanel: NSPanel {
    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { false }
}

// MARK: - 2. Data Models for Eney Messages, Screen Context & Quick Commands
public struct EneyMessage: Identifiable, Hashable {
    public let id = UUID()
    public let role: String // "user", "assistant", "proactive"
    public let text: String
    public let timestamp: Date = Date()
    public let actionTitle: String?
    public let actionKey: String?
}

public struct AXWindowContext: Hashable {
    public var appName: String = "Bilinmiyor"
    public var bundleID: String = ""
    public var windowTitle: String = ""
    public var selectedText: String = ""
    public var visibleButtons: [String] = []
    public var onScreenWindowList: [String] = []
    public var activeBrowserURL: String = ""
    public var selectedFinderPath: String = ""
    public var screenOCRText: String = ""
    public var screenOCRLineCount: Int = 0
}

public struct EneySpotlightCommand: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let icon: String
    public let accent: Color
    public let shortcutBadge: String
    public let actionKey: String
}

// MARK: - 3. Eney AI Spotlight Overlay View (Castor + Tinycast + macOS-Visual-Agent Architecture)
public struct EneySpotlightOverlayView: View {
    @ObservedObject var eney: EneyAIAgentManager
    public var isFloatingWindow: Bool = true
    @FocusState private var isSearchFocused: Bool

    public var body: some View {
        let filteredCommands = eney.filteredSpotlightCommands()

        VStack(spacing: 0) {
            // 1. Top Spotlight Search & AI Prompt Bar
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                        .shadow(color: .purple.opacity(0.6), radius: 8)

                    Image(systemName: eney.isGenerating ? "rays" : "sparkles")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }

                TextField("Eney'e sor, 'ekranda ne var' yaz, komut ara veya hesaplama yap (örn: 1450*1.20)...", text: $eney.spotlightQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .focused($isSearchFocused)
                    .onSubmit {
                        eney.submitSpotlightQuery()
                    }

                if let calcResult = eney.inlineCalculatorResult {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(calcResult, forType: .string)
                        eney.spotlightLastResponse = "✅ Hesaplama sonucu panoya kopyalandı: \(calcResult)"
                    } label: {
                        HStack(spacing: 5) {
                            Text("= \(calcResult)")
                                .font(.system(size: 14, weight: .heavy, design: .monospaced))
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 10))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.25))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    eney.submitSpotlightQuery()
                } label: {
                    HStack(spacing: 4) {
                        Text("Sor / Çalıştır")
                            .font(.system(size: 11.5, weight: .bold))
                        Image(systemName: "return")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        LinearGradient(colors: [.purple, .cyan.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                if isFloatingWindow {
                    Button {
                        eney.dismissSpotlightOverlay()
                    } label: {
                        Text("ESC")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.09))
                            .foregroundStyle(.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.04))

            Divider().background(Color.white.opacity(0.12))

            // 2. Live Screen Vision & Context Strip ("Şu An Ekranda Neler Var?")
            HStack(spacing: 12) {
                // Live Screen Capture Thumbnail
                ZStack(alignment: .bottomLeading) {
                    if let shot = eney.latestScreenSnapshot {
                        Image(nsImage: shot)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 96, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    } else {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.purple.opacity(0.18))
                            .frame(width: 96, height: 56)
                            .overlay(
                                Image(systemName: "display")
                                    .font(.title3)
                                    .foregroundStyle(.cyan)
                            )
                    }

                    Text("CANLI EKRAN")
                        .font(.system(size: 7.5, weight: .heavy, design: .monospaced))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.78))
                        .foregroundStyle(.cyan)
                        .clipShape(Capsule())
                        .padding(4)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.cyan.opacity(0.45), lineWidth: 1)
                )

                // Discovered Screen Context Chips
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Label(
                            "Aktif: \(eney.activeContext.appName)\(eney.activeContext.windowTitle.isEmpty ? "" : " — \(eney.activeContext.windowTitle)")",
                            systemImage: "macwindow"
                        )
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.cyan)
                        .lineLimit(1)

                        Spacer()

                        Button {
                            eney.harvestFullScreenAndOSContext(captureBeforeOpening: false)
                        } label: {
                            Label(eney.isScanningScreen ? "Taranıyor..." : "Ekranı Yeniden Oku", systemImage: "viewfinder")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.cyan.opacity(0.18))
                                .foregroundStyle(.cyan)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            eney.analyzeWhatsOnMyScreenNow()
                        } label: {
                            Label("👁️ Ekranda Ne Var Analiz Et", systemImage: "sparkles.tv.fill")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 3)
                                .background(Color.purple.opacity(0.28))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    // Context Badges Row (Vision OCR + Open Windows + Finder Selection)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ContextBadgePill(
                                icon: "text.viewfinder",
                                text: eney.activeContext.screenOCRLineCount > 0
                                    ? "Ekran OCR: \(eney.activeContext.screenOCRLineCount) satır okundu"
                                    : "Açık Pencere: \(eney.activeContext.onScreenWindowList.count) adet",
                                color: .green
                            )

                            if !eney.activeContext.selectedFinderPath.isEmpty {
                                ContextBadgePill(
                                    icon: "folder.fill",
                                    text: "Finder: \(URL(fileURLWithPath: eney.activeContext.selectedFinderPath).lastPathComponent)",
                                    color: .orange
                                )
                            }

                            if !eney.activeContext.activeBrowserURL.isEmpty {
                                ContextBadgePill(
                                    icon: "safari.fill",
                                    text: eney.activeContext.activeBrowserURL,
                                    color: .blue
                                )
                            }

                            if !eney.activeContext.selectedText.isEmpty {
                                ContextBadgePill(
                                    icon: "doc.on.clipboard.fill",
                                    text: "Seçili/Pano: \(eney.activeContext.selectedText.prefix(38))...",
                                    color: .purple
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.32))

            Divider().background(Color.white.opacity(0.10))

            // 3. Two-Column Interactive Workspace: Left = Quick Actions / Commands, Right = Live Eney Screen & AI Response
            HStack(alignment: .top, spacing: 0) {
                // Left Column: Fuzzy Command List
                VStack(alignment: .leading, spacing: 6) {
                    Text("⚡ HIZLI ENEY & EKRAN EYLEMLERİ")
                        .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 10)

                    ScrollView {
                        VStack(spacing: 5) {
                            ForEach(filteredCommands) { cmd in
                                Button {
                                    eney.runSpotlightCommand(cmd)
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: cmd.icon)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                            .frame(width: 30, height: 30)
                                            .background(cmd.accent.opacity(0.28))
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(cmd.title)
                                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                                .foregroundStyle(.white)
                                                .lineLimit(1)
                                            Text(cmd.subtitle)
                                                .font(.system(size: 10))
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        Text(cmd.shortcutBadge)
                                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.white.opacity(0.07))
                                            .foregroundStyle(.secondary)
                                            .clipShape(Capsule())
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color.white.opacity(0.04))
                                    )
                                    .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom, 10)
                    }
                }
                .frame(width: 335)

                Divider().background(Color.white.opacity(0.10))

                // Right Column: Live Eney Screen Analysis & Conversational Output
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("🤖 ENEY AI CANLI YANIT & EKRAN GÖRÜŞÜ", systemImage: "brain.head.profile")
                            .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                            .foregroundStyle(.purple)
                        Spacer()
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(eney.spotlightLastResponse, forType: .string)
                        } label: {
                            Label("Kopyala", systemImage: "doc.on.doc")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.cyan)
                        }
                        .buttonStyle(.plain)
                    }

                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(eney.spotlightLastResponse)
                                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.95))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if !eney.activeContext.screenOCRText.isEmpty {
                                Divider().background(Color.white.opacity(0.12))
                                Text("👁️ Ekrandan Okunan Canlı Metinler (Vision OCR):")
                                    .font(.system(size: 10.5, weight: .bold))
                                    .foregroundStyle(.cyan)
                                Text(String(eney.activeContext.screenOCRText.prefix(550)))
                                    .font(.system(size: 10.5, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.75))
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white.opacity(0.04))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }

                    // Bottom Quick Prompt Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            QuickPromptChip(title: "👁️ Ekranda ne var özetle") {
                                eney.analyzeWhatsOnMyScreenNow()
                            }
                            QuickPromptChip(title: "🔒 Hassas verileri maskele") {
                                eney.spotlightQuery = "Ekrandaki ve panodaki hassas verileri maskele"
                                eney.runWandAction("mask_pii")
                                eney.spotlightLastResponse = "🔒 **Maskelenmiş Metin:**\n\(eney.wandOutputText)"
                            }
                            QuickPromptChip(title: "🔥 RAM & CPU Analizi") {
                                eney.spotlightQuery = "RAM ve CPU durumunu analiz et"
                                eney.submitSpotlightQuery()
                            }
                            QuickPromptChip(title: "📂 İndirilenleri Düzenle") {
                                eney.executeWorkflow(key: "scan_downloads")
                                eney.spotlightLastResponse = "📂 ~/Downloads klasörü AI Dosya Düzenleyici ile tarandı ve sınıflandırma önerileri hazırlandı!"
                            }
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(height: 310)

            Divider().background(Color.white.opacity(0.10))

            // 4. Bottom Shortcut Footer Bar
            HStack {
                Label("Çift ⌥ Option veya ⌥ + Space ile her yerden aç/kapat", systemImage: "command.square.fill")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Model: \(eney.selectedModel)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.purple)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.45))
        }
        .frame(width: 760)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.05, green: 0.06, blue: 0.10).opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.purple.opacity(0.75), .cyan.opacity(0.55), .white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.75), radius: 30, y: 14)
        .onAppear {
            isSearchFocused = true
        }
    }
}

private struct ContextBadgePill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9.5, weight: .bold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .overlay(Capsule().strokeBorder(color.opacity(0.4), lineWidth: 0.8))
        .clipShape(Capsule())
    }
}

private struct QuickPromptChip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.purple.opacity(0.18))
                .overlay(Capsule().strokeBorder(Color.purple.opacity(0.45), lineWidth: 0.8))
                .foregroundStyle(.white)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 4. EneyAIAgentManager (Double-Tap Option Monitor + Screen Vision OCR + Spotlight Engine)
@MainActor
public final class EneyAIAgentManager: ObservableObject {
    public static let shared = EneyAIAgentManager()

    @Published public var messages: [EneyMessage] = [
        EneyMessage(
            role: "proactive",
            text: "Merhaba! Ben Eney OS Ajanı (PikoChan + AXorcist + Castor + Tinycast çekirdekli). Klavyeden çift ⌥ Option (veya ⌥ + Space) tuşuna bastığında Spotlight çubuğum açılır, o an ekranında ne olduğunu Vision OCR ile okur ve tüm isteklerini yerine getiririm!",
            actionTitle: "👁️ Ekranda Ne Var Analiz Et",
            actionKey: "analyze_screen"
        )
    ]
    @Published public var availableModels: [String] = ["qwen2.5:3b", "llama3.2:3b", "apple-on-device-nl"]
    @Published public var selectedModel: String = "apple-on-device-nl"
    @Published public var isOllamaConnected: Bool = false
    @Published public var isGenerating: Bool = false

    // AXorcist + ScreenCaptureKit + Vision OCR Context
    @Published public var activeContext = AXWindowContext()
    @Published public var latestScreenSnapshot: NSImage? = nil
    @Published public var isScanningScreen: Bool = false

    // Eney Spotlight Launcher State (Double-Tap Option / Option+Space)
    @Published public var isOptionSpotlightEnabled: Bool = true
    @Published public var isSpotlightVisible: Bool = false
    @Published public var spotlightQuery: String = ""
    @Published public var spotlightLastResponse: String = "👋 Çift ⌥ Option ile Eney Spotlight açıldı! Ekranda açık olan pencerelerinizi, seçili dosyalarınızı ve ekran üzerindeki tüm yazıları (Vision OCR) gerçek zamanlı görebiliyorum. Yukarıdan bir soru sorun veya soldan hızlı eylem seçin."

    // Eney Wand (Option + W) State
    @Published public var wandInputText: String = ""
    @Published public var wandOutputText: String = ""
    @Published public var isWandVisible: Bool = false

    private let eventStore = EKEventStore()
    private var spotlightPanel: EneySpotlightFloatingPanel?
    private var globalFlagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?
    private var lastOptionPressTimestamp: TimeInterval = 0
    private var wasOptionDown: Bool = false
    private var previousFrontAppBeforeSpotlight: NSRunningApplication?

    private init() {
        discoverLocalOllamaModels()
        harvestFullScreenAndOSContext(captureBeforeOpening: false)
        startOptionKeySpotlightMonitor()
    }

    // MARK: - Inline Math Calculator for Spotlight Query (Tinycast / Raycast feature)
    public var inlineCalculatorResult: String? {
        let trimmed = spotlightQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return nil }
        let allowed = CharacterSet(charactersIn: "0123456789.+-*/() ")
        guard trimmed.unicodeScalars.allSatisfy({ allowed.contains($0) }),
              trimmed.contains(where: { "+-*/".contains($0) }) else {
            return nil
        }
        // Safe numeric expression evaluation
        let sanitized = trimmed.replacingOccurrences(of: ",", with: ".")
        let chars = Array(sanitized)
        // Avoid NSExpression crash on trailing operator
        if let last = chars.last, "+-*/(".contains(last) { return nil }
        let exp = NSExpression(format: sanitized)
        if let num = exp.expressionValue(with: nil, context: nil) as? NSNumber {
            let val = num.doubleValue
            if val.isFinite {
                return val.truncatingRemainder(dividingBy: 1) == 0
                    ? String(format: "%.0f", val)
                    : String(format: "%.2f", val)
            }
        }
        return nil
    }

    // MARK: - 1. Global Double-Tap Option (⌥) & Option+Space / Option+W Monitor
    public func startOptionKeySpotlightMonitor() {
        stopOptionKeySpotlightMonitor()

        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleOptionFlagsChanged(event)
            }
        }

        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleOptionFlagsChanged(event)
            }
            return event
        }

        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleGlobalKeyDown(event)
            }
        }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self else { return event }
            // ESC closes Spotlight if visible
            if self.isSpotlightVisible && event.keyCode == 53 {
                Task { @MainActor in self.dismissSpotlightOverlay() }
                return nil
            }
            // Option + Space (keyCode 49) or Option + W (keyCode 13)
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == .option && (event.keyCode == 49 || event.keyCode == 13) {
                Task { @MainActor in self.toggleSpotlightOverlay() }
                return nil
            }
            return event
        }
    }

    public func stopOptionKeySpotlightMonitor() {
        if let globalFlagsMonitor { NSEvent.removeMonitor(globalFlagsMonitor) }
        if let localFlagsMonitor { NSEvent.removeMonitor(localFlagsMonitor) }
        if let globalKeyMonitor { NSEvent.removeMonitor(globalKeyMonitor) }
        if let localKeyMonitor { NSEvent.removeMonitor(localKeyMonitor) }
        globalFlagsMonitor = nil
        localFlagsMonitor = nil
        globalKeyMonitor = nil
        localKeyMonitor = nil
    }

    private func handleOptionFlagsChanged(_ event: NSEvent) {
        guard isOptionSpotlightEnabled else { return }
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Check if ONLY the Option (⌥) key was pressed down
        if flags == .option {
            if !wasOptionDown {
                wasOptionDown = true
                let now = CACurrentMediaTime()
                if now - lastOptionPressTimestamp < 0.42 {
                    // Double-Tap Option Detected!
                    lastOptionPressTimestamp = 0
                    toggleSpotlightOverlay()
                } else {
                    lastOptionPressTimestamp = now
                }
            }
        } else {
            wasOptionDown = false
        }
    }

    private func handleGlobalKeyDown(_ event: NSEvent) {
        guard isOptionSpotlightEnabled else { return }
        // If another key is pressed while Option is held, cancel the single-Option tap timer
        lastOptionPressTimestamp = 0
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        // Option + Space (49) or Option + W (13)
        if flags == .option && (event.keyCode == 49 || event.keyCode == 13) {
            toggleSpotlightOverlay()
        }
    }

    // MARK: - 2. Show / Toggle Floating Eney Spotlight Overlay Panel
    public func toggleSpotlightOverlay() {
        if isSpotlightVisible {
            dismissSpotlightOverlay()
        } else {
            showSpotlightOverlay()
        }
    }

    public func showSpotlightOverlay() {
        // Remember which app the user was looking at BEFORE opening Spotlight!
        if let front = NSWorkspace.shared.frontmostApplication,
           front.bundleIdentifier != Bundle.main.bundleIdentifier {
            previousFrontAppBeforeSpotlight = front
        }

        // Harvest everything currently on the user's screen right now!
        harvestFullScreenAndOSContext(captureBeforeOpening: true)

        let panelWidth: CGFloat = 760
        let panelHeight: CGFloat = 510
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let originX = screenFrame.midX - (panelWidth / 2.0)
        let originY = screenFrame.maxY - panelHeight - 110
        let frame = NSRect(x: originX, y: originY, width: panelWidth, height: panelHeight)

        if spotlightPanel == nil {
            let panel = EneySpotlightFloatingPanel(
                contentRect: frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.level = .screenSaver
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            panel.acceptsMouseMovedEvents = true
            panel.becomesKeyOnlyIfNeeded = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.contentView = NSHostingView(
                rootView: EneySpotlightOverlayView(eney: self, isFloatingWindow: true)
            )
            spotlightPanel = panel
        } else {
            spotlightPanel?.setFrame(frame, display: true)
        }

        NSApp.activate(ignoringOtherApps: true)
        spotlightPanel?.makeKeyAndOrderFront(nil)
        isSpotlightVisible = true
    }

    public func dismissSpotlightOverlay() {
        spotlightPanel?.orderOut(nil)
        isSpotlightVisible = false
    }

    // MARK: - 3. Full Screen & OS Context Harvester (AXorcist + CGWindowList + ScreenCaptureKit + Vision OCR)
    public func harvestFullScreenAndOSContext(captureBeforeOpening: Bool) {
        let targetApp = (captureBeforeOpening ? previousFrontAppBeforeSpotlight : nil)
            ?? NSWorkspace.shared.frontmostApplication

        var ctx = activeContext
        if let app = targetApp {
            ctx.appName = app.localizedName ?? "macOS"
            ctx.bundleID = app.bundleIdentifier ?? ""
        }

        // 1. Enumerate all visible on-screen windows via CGWindowListCopyWindowInfo (Requires ZERO permissions!)
        if let windowInfoList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] {
            var discoveredWindows: [String] = []
            for info in windowInfoList {
                let layer = (info[kCGWindowLayer as String] as? Int) ?? 0
                guard layer == 0 else { continue }
                let owner = (info[kCGWindowOwnerName as String] as? String) ?? ""
                let title = (info[kCGWindowName as String] as? String) ?? ""
                guard !owner.isEmpty, owner != "Window Server", owner != "SuperMacHub" else { continue }
                let label = title.isEmpty ? owner : "\(owner): \(title)"
                if !discoveredWindows.contains(label) {
                    discoveredWindows.append(label)
                }
            }
            ctx.onScreenWindowList = Array(discoveredWindows.prefix(10))
            if ctx.windowTitle.isEmpty, let firstMatch = discoveredWindows.first(where: { $0.hasPrefix(ctx.appName) }) {
                ctx.windowTitle = firstMatch.replacingOccurrences(of: "\(ctx.appName): ", with: "")
            }
        }

        // 2. Inspect Focused Window & Selected Text via AXUIElement (AXorcist)
        if AXIsProcessTrusted(), let app = targetApp {
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            var focusedWindow: CFTypeRef?
            if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow) == .success,
               let win = focusedWindow {
                var titleRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(win as! AXUIElement, kAXTitleAttribute as CFString, &titleRef) == .success,
                   let title = titleRef as? String, !title.isEmpty {
                    ctx.windowTitle = title
                }

                var childrenRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(win as! AXUIElement, kAXChildrenAttribute as CFString, &childrenRef) == .success,
                   let children = childrenRef as? [AXUIElement] {
                    var buttons: [String] = []
                    for child in children.prefix(25) {
                        var titleVal: CFTypeRef?
                        if AXUIElementCopyAttributeValue(child, kAXTitleAttribute as CFString, &titleVal) == .success,
                           let btnTitle = titleVal as? String, !btnTitle.isEmpty {
                            buttons.append(btnTitle)
                        }
                    }
                    ctx.visibleButtons = buttons
                }
            }

            var focusedElement: CFTypeRef?
            if AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success,
               let el = focusedElement {
                var selTextRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(el as! AXUIElement, kAXSelectedTextAttribute as CFString, &selTextRef) == .success,
                   let sel = selTextRef as? String, !sel.isEmpty {
                    ctx.selectedText = sel
                }
            }
        }

        // 3. Clipboard Preview
        if ctx.selectedText.isEmpty, let clip = NSPasteboard.general.string(forType: .string), !clip.isEmpty {
            ctx.selectedText = String(clip.prefix(280))
        }

        // 4. Selected File in Finder
        if !NashiToolkitManager.shared.selectedFilePath.isEmpty {
            ctx.selectedFinderPath = NashiToolkitManager.shared.selectedFilePath
        }

        activeContext = ctx

        // 5. Capture Live Screen Image & Run Apple Vision OCR asynchronously via ScreenCaptureKit
        captureScreenAndRunVisionOCR()
    }

    public func refreshActiveAppContext() {
        harvestFullScreenAndOSContext(captureBeforeOpening: false)
    }

    private func captureScreenAndRunVisionOCR() {
        guard !isScanningScreen else { return }
        isScanningScreen = true

        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                guard let display = content.displays.first else {
                    self.isScanningScreen = false
                    return
                }
                let filter = SCContentFilter(display: display, excludingWindows: [])
                let config = SCStreamConfiguration()
                config.width = min(1440, Int(display.width))
                config.height = min(900, Int(display.height))
                config.showsCursor = false

                let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                self.latestScreenSnapshot = nsImage

                // Run Apple Vision OCR on captured screen image
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .fast
                request.usesLanguageCorrection = true
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])

                let lines = (request.results ?? [])
                    .compactMap { $0.topCandidates(1).first?.string }
                    .filter { $0.count > 2 }

                self.activeContext.screenOCRLineCount = lines.count
                self.activeContext.screenOCRText = lines.prefix(35).joined(separator: " • ")
            } catch {
                // Even if Screen Recording permission is not granted yet, window & AX context is still populated
            }
            self.isScanningScreen = false
        }
    }

    // MARK: - 4. Analyze What Is Currently On Screen ("Ekranda Neler Var?")
    public func analyzeWhatsOnMyScreenNow() {
        let stats = StatsEngine.shared
        let windowsSummary = activeContext.onScreenWindowList.isEmpty
            ? activeContext.appName
            : activeContext.onScreenWindowList.prefix(6).joined(separator: "\n  • ")

        let ocrSnippet = activeContext.screenOCRText.isEmpty
            ? "(Tam ekran piksel OCR için Ekran Kaydı izni verebilirsiniz; pencere ağacı aktif)"
            : String(activeContext.screenOCRText.prefix(420))

        let report = """
        👁️ **Anlık Ekran & Bağlam Analizi (Eney Visual Agent):**
        • **Odaktaki Uygulama:** `\(activeContext.appName)` \(activeContext.windowTitle.isEmpty ? "" : "(\(activeContext.windowTitle))")
        • **Ekranda Açık Olan Pencereler:**
          • \(windowsSummary)
        • **Finder Seçili Dosya:** `\(activeContext.selectedFinderPath.isEmpty ? "Yok" : URL(fileURLWithPath: activeContext.selectedFinderPath).lastPathComponent)`
        • **Pano / Seçili Metin:** \(activeContext.selectedText.isEmpty ? "Boş" : "\"\(activeContext.selectedText.prefix(90))...\"")
        • **Vision OCR Ekran Metin Özeti (\(activeContext.screenOCRLineCount) satır):**
          \(ocrSnippet)
        • **Sistem Durumu:** CPU %\(Int(stats.cpuUsagePercent)) • RAM \(String(format: "%.1f", stats.memoryUsedGB))/\(Int(stats.memoryTotalGB)) GB
        """

        spotlightLastResponse = report
        messages.append(EneyMessage(role: "assistant", text: report, actionTitle: "İndirilenleri Düzenle", actionKey: "scan_downloads"))

        // If Ollama is connected, also enrich with LLM insight
        if selectedModel != "apple-on-device-nl" {
            Task {
                if let llmInsight = await callOllamaChat(
                    model: selectedModel,
                    system: "Kullanıcının ekranındaki açık pencereleri ve Vision OCR metinlerini inceleyip 3 maddede ne üzerinde çalıştığını ve nasıl yardımcı olabileceğini Türkçe özetle.",
                    user: report
                ) {
                    self.spotlightLastResponse = report + "\n\n🤖 **AI Önerisi:**\n" + llmInsight
                }
            }
        }
    }

    // MARK: - 5. Spotlight Quick Commands & Search Filtering
    public var allSpotlightCommands: [EneySpotlightCommand] {
        [
            EneySpotlightCommand(
                id: "cmd_screen_vision",
                title: "👁️ Şu An Ekranımda Ne Var Analiz Et",
                subtitle: "Açık pencereleri, Vision OCR metinlerini ve aktif işi özetle",
                icon: "sparkles.tv.fill",
                accent: .purple,
                shortcutBadge: "⏎",
                actionKey: "analyze_screen"
            ),
            EneySpotlightCommand(
                id: "cmd_nashi_wheel",
                title: "🍐 Seçili Dosyada Nashi 360° Çarkını Aç",
                subtitle: "Dönüştürme, Vision Arka Plan Silici ve Dinamik Ada Çarkı",
                icon: "circle.hexagongrid.fill",
                accent: .orange,
                shortcutBadge: "⇧+Tık",
                actionKey: "open_nashi_wheel"
            ),
            EneySpotlightCommand(
                id: "cmd_organize_downloads",
                title: "🧹 İndirilenler Klasörünü AI ile Düzenle",
                subtitle: "Magika + Vision OCR ile ~/Downloads klasörünü kategorize et",
                icon: "folder.fill.badge.gearshape",
                accent: .indigo,
                shortcutBadge: "AI",
                actionKey: "scan_downloads"
            ),
            EneySpotlightCommand(
                id: "cmd_mask_pii",
                title: "🔒 Ekrandaki / Panodaki Hassas Verileri Maskele",
                subtitle: "IBAN, Kredi Kartı, E-Posta ve API anahtarlarını gizle",
                icon: "lock.shield.fill",
                accent: .orange,
                shortcutBadge: "⌥+W",
                actionKey: "mask_pii"
            ),
            EneySpotlightCommand(
                id: "cmd_freeze_ram",
                title: "❄️ En Çok RAM/CPU Yiyen Süreci Dondur",
                subtitle: "SIGSTOP ile arka plan sürecini uyutarak Mac'i hızlandır",
                icon: "snowflake",
                accent: .cyan,
                shortcutBadge: "Stats",
                actionKey: "freeze_top_process"
            ),
            EneySpotlightCommand(
                id: "cmd_faceid_scan",
                title: "🔓 Dinamik Ada'da Face ID Taraması Başlat",
                subtitle: "Kameradan yüz ve göz kırpma canlılığını doğrula",
                icon: "faceid",
                accent: .green,
                shortcutBadge: "FaceID",
                actionKey: "trigger_faceid"
            ),
            EneySpotlightCommand(
                id: "cmd_app_shield",
                title: "🛡️ FaceGate Tam Ekran Kilit Kalkanını Aç",
                subtitle: "Ekranı buzlu cam kalkanla kilitle ve yüzle aç",
                icon: "lock.desktopcomputer",
                accent: .pink,
                shortcutBadge: "Kalkan",
                actionKey: "trigger_shield"
            ),
            EneySpotlightCommand(
                id: "cmd_morning_brief",
                title: "☀️ Günlük Sistem & Takvim Sabah Özeti",
                subtitle: "Donanım sağlığı, pil, disk ve çalışma raporu",
                icon: "sun.max.fill",
                accent: .yellow,
                shortcutBadge: "Özet",
                actionKey: "morning_brief"
            )
        ]
    }

    public func filteredSpotlightCommands() -> [EneySpotlightCommand] {
        let q = spotlightQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return allSpotlightCommands }
        let matches = allSpotlightCommands.filter {
            $0.title.localizedCaseInsensitiveContains(q) ||
            $0.subtitle.localizedCaseInsensitiveContains(q)
        }
        return matches.isEmpty ? allSpotlightCommands : matches
    }

    public func runSpotlightCommand(_ cmd: EneySpotlightCommand) {
        switch cmd.actionKey {
        case "analyze_screen":
            analyzeWhatsOnMyScreenNow()
        case "open_nashi_wheel":
            dismissSpotlightOverlay()
            NashiToolkitManager.shared.captureFinderSelectionOrDragPasteboard()
            NashiToolkitManager.shared.showRadialWheelAtCursor()
        case "scan_downloads":
            executeWorkflow(key: "scan_downloads")
            spotlightLastResponse = "✅ `~/Downloads` klasörü AI Dosya Düzenleyici ile analiz edildi! Sonuçları onaylamak için AI Dosya Düzenleyici sekmesine geçebilirsiniz."
        case "mask_pii":
            runWandAction("mask_pii")
            spotlightLastResponse = "🔒 **Hassas Veriler Maskelendi:**\n\(wandOutputText)"
        case "freeze_top_process":
            executeWorkflow(key: "freeze_top_process")
            if let top = StatsEngine.shared.topProcesses.first {
                spotlightLastResponse = "❄️ En çok kaynak tüketen `\(top.name)` (PID \(top.pid)) süreci SIGSTOP ile donduruldu!"
            }
        case "trigger_faceid":
            dismissSpotlightOverlay()
            DynamicIslandNotchManager.shared.setExpanded(false)
            FaceIDVisionManager.shared.performQuickFaceScan()
        case "trigger_shield":
            dismissSpotlightOverlay()
            FaceIDVisionManager.shared.simulateAppLockChallenge()
        case "morning_brief":
            executeWorkflow(key: "morning_brief")
            if let last = messages.last {
                spotlightLastResponse = last.text
            }
        default:
            break
        }
    }

    public func submitSpotlightQuery() {
        let trimmed = spotlightQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            analyzeWhatsOnMyScreenNow()
            return
        }

        if let calc = inlineCalculatorResult {
            spotlightLastResponse = "🧮 **Hesaplama Sonucu:**\n`\(trimmed) = \(calc)` (Panoya kopyalamak için yeşil sonuca tıklayın)"
            return
        }

        let lower = trimmed.lowercased()
        if lower.contains("ekran") || lower.contains("ne var") || lower.contains("görüyorsun") || lower.contains("oku") {
            analyzeWhatsOnMyScreenNow()
            return
        }

        sendUserPrompt(trimmed)
        if let last = messages.last {
            spotlightLastResponse = "⏳ **Eney düşünüyor...**\n\(last.text)"
        }
    }

    // MARK: - Ollama Discovery (Disk + Localhost API)
    public func discoverLocalOllamaModels() {
        var found: [String] = []
        let manifestPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".ollama/models/manifests/registry.ollama.ai/library")

        if let modelDirs = try? FileManager.default.contentsOfDirectory(atPath: manifestPath.path) {
            for model in modelDirs where !model.hasPrefix(".") {
                let tagDir = manifestPath.appendingPathComponent(model)
                if let tags = try? FileManager.default.contentsOfDirectory(atPath: tagDir.path) {
                    for tag in tags where !tag.hasPrefix(".") {
                        found.append("\(model):\(tag)")
                    }
                }
            }
        }

        if !found.isEmpty {
            availableModels = found + ["apple-on-device-nl"]
            selectedModel = found[0]
        }

        guard let url = URL(string: "http://127.0.0.1:11434/api/tags") else { return }
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let http = response as? HTTPURLResponse, http.statusCode == 200,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let models = json["models"] as? [[String: Any]] {
                    let names = models.compactMap { $0["name"] as? String }
                    if !names.isEmpty {
                        self.availableModels = names + ["apple-on-device-nl"]
                        self.selectedModel = names[0]
                        self.isOllamaConnected = true
                    }
                }
            } catch {
                self.isOllamaConnected = false
            }
        }
    }

    // MARK: - Proactive Health Check (Stats -> Eney Bridge)
    public func checkProactiveSystemInterventions(stats: StatsEngine) {
        if stats.memoryPressurePercent > 80 {
            let msg = EneyMessage(
                role: "proactive",
                text: "⚠️ Bellek baskısı %\(Int(stats.memoryPressurePercent)) seviyesine çıktı (\(String(format: "%.1f", stats.memoryUsedGB)) GB kullanımda). En çok CPU/RAM tüketen arka plan sürecini dondurmamı ister misin?",
                actionTitle: "Ağır Süreci Dondur",
                actionKey: "freeze_top_process"
            )
            if !messages.contains(where: { $0.actionKey == "freeze_top_process" }) {
                messages.append(msg)
            }
        }
    }

    // MARK: - Apple-MCP Native Workflows (Calendar, Reminders, Finder, System)
    public func executeWorkflow(key: String) {
        switch key {
        case "analyze_screen":
            analyzeWhatsOnMyScreenNow()

        case "morning_brief":
            let stats = StatsEngine.shared
            let summary = """
            ☀️ **Günlük Sistem & Ekran Özeti (Eney Morning Brief):**
            • **Donanım Sağlığı:** CPU %\(Int(stats.cpuUsagePercent)), Bellek \(String(format: "%.1f", stats.memoryUsedGB))/\(Int(stats.memoryTotalGB)) GB, Pil %\(stats.batteryPercent) (\(stats.thermalStateLabel))
            • **Boş Disk Alanı:** \(String(format: "%.1f", stats.diskFreeGB)) GB kullanılabilir
            • **Aktif Uygulama Bağlamı:** \(activeContext.appName) \(activeContext.windowTitle.isEmpty ? "" : "— \(activeContext.windowTitle)")
            • **Ekranda Açık Pencereler:** \(activeContext.onScreenWindowList.prefix(4).joined(separator: ", "))
            """
            messages.append(EneyMessage(role: "assistant", text: summary, actionTitle: "İndirilenleri Tara", actionKey: "scan_downloads"))

        case "freeze_top_process":
            if let top = StatsEngine.shared.topProcesses.first {
                StatsEngine.shared.toggleSuspendProcess(pid: top.pid)
                messages.append(EneyMessage(role: "assistant", text: "✅ `\(top.name)` (PID: \(top.pid)) süreci SIGSTOP ile donduruldu. İstediğin zaman Stats sekmesinden devam ettirebilirsin.", actionTitle: nil, actionKey: nil))
            }

        case "scan_downloads":
            AIFileOrganizerManager.shared.scanFolder(path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads").path)
            messages.append(EneyMessage(role: "assistant", text: "📂 `~/Downloads` klasörü tarandı ve Dry-Run önizleme listesi hazırlandı! AI Dosya Düzenleyici sekmesinden onaylayabilirsin.", actionTitle: nil, actionKey: nil))

        default:
            break
        }
    }

    // MARK: - Chat with Eney (Ollama API + Screen Context + On-Device Fallback)
    public func sendUserPrompt(_ prompt: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(EneyMessage(role: "user", text: trimmed, actionTitle: nil, actionKey: nil))
        harvestFullScreenAndOSContext(captureBeforeOpening: false)
        isGenerating = true

        let stats = StatsEngine.shared
        let systemPrompt = """
        Sen SuperMacHub içinde çalışan Eney AI OS Asistanısın. Türkçe, net ve aksiyon odaklı yanıt ver.
        Anlık Sistem Durumu: CPU %\(Int(stats.cpuUsagePercent)), RAM \(String(format: "%.1f", stats.memoryUsedGB))/\(Int(stats.memoryTotalGB)) GB, Boş Disk \(String(format: "%.1f", stats.diskFreeGB)) GB, Pil %\(stats.batteryPercent).
        Aktif Uygulama: \(activeContext.appName) (\(activeContext.windowTitle)).
        Ekranda Açık Pencereler: \(activeContext.onScreenWindowList.joined(separator: ", ")).
        Ekran Vision OCR Metinleri: \(String(activeContext.screenOCRText.prefix(500))).
        """

        Task {
            if selectedModel != "apple-on-device-nl",
               let reply = await callOllamaChat(model: selectedModel, system: systemPrompt, user: trimmed) {
                self.messages.append(EneyMessage(role: "assistant", text: reply, actionTitle: nil, actionKey: nil))
                self.spotlightLastResponse = reply
                self.isGenerating = false
                return
            }

            let reply = generateOnDeviceResponse(for: trimmed, stats: stats)
            self.messages.append(EneyMessage(role: "assistant", text: reply.text, actionTitle: reply.actionTitle, actionKey: reply.actionKey))
            self.spotlightLastResponse = reply.text
            self.isGenerating = false
        }
    }

    private func callOllamaChat(model: String, system: String, user: String) async -> String? {
        guard let url = URL(string: "http://127.0.0.1:11434/api/chat") else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 18

        let body: [String: Any] = [
            "model": model,
            "stream": false,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ]
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let msg = json["message"] as? [String: Any],
                  let content = msg["content"] as? String else { return nil }
            isOllamaConnected = true
            return content
        } catch {
            return nil
        }
    }

    private func generateOnDeviceResponse(for input: String, stats: StatsEngine) -> (text: String, actionTitle: String?, actionKey: String?) {
        let lower = input.lowercased()
        if lower.contains("ekran") || lower.contains("ne var") || lower.contains("pencere") {
            let wins = activeContext.onScreenWindowList.prefix(5).joined(separator: ", ")
            return (
                "👁️ **Ekran Görüşü Raporu:**\n• **Odaktaki Uygulama:** `\(activeContext.appName)` (\(activeContext.windowTitle))\n• **Açık Pencereler:** \(wins)\n• **Vision OCR:** Ekranda \(activeContext.screenOCRLineCount) satır metin algılandı.\n• **Seçili Dosya:** `\(URL(fileURLWithPath: activeContext.selectedFinderPath).lastPathComponent)`",
                "👁️ Tam Ekran Analizi",
                "analyze_screen"
            )
        } else if lower.contains("ram") || lower.contains("bellek") || lower.contains("cpu") || lower.contains("sistem") {
            let topName = stats.topProcesses.first?.name ?? "Bilinmiyor"
            return (
                "Anlık sistem analizi:\n• **CPU Kullanımı:** %\( String(format: "%.1f", stats.cpuUsagePercent) )\n• **RAM Kullanımı:** \(String(format: "%.1f", stats.memoryUsedGB)) GB / \(Int(stats.memoryTotalGB)) GB (%\(Int(stats.memoryPressurePercent)) baskı)\n• **En Çok Kaynak Tüketen:** `\(topName)`\n• **Pil & Isı:** %\(stats.batteryPercent) — \(stats.thermalStateLabel)",
                "Ağır Süreci Dondur",
                "freeze_top_process"
            )
        } else if lower.contains("dosya") || lower.contains("indirilen") || lower.contains("düzenle") || lower.contains("downloads") {
            return (
                "AI Dosya Düzenleyici modülü ile `~/Downloads` veya `~/Desktop` klasöründeki PDF, ekran görüntüsü, fatura ve kurulum paketlerini içeriklerine göre sınıflandırabilirim.",
                "İndirilenleri Şimdi Tara",
                "scan_downloads"
            )
        } else {
            let wins = activeContext.onScreenWindowList.prefix(3).joined(separator: ", ")
            return (
                "🤖 **Eney OS Ajanı Yanıtı (`\( input )`):**\n• **Aktif Ekran Bağlamı:** `\(activeContext.appName)` (Açık pencereler: \(wins))\n• **Ekran OCR:** \(activeContext.screenOCRLineCount) satır okundu.\n• İstersen ekranındaki metinleri özetleyebilir, seçili dosyayı Nashi çarkıyla dönüştürebilir veya ağır süreçleri dondurabilirim.",
                "👁️ Ekranda Ne Var Analiz Et",
                "analyze_screen"
            )
        }
    }

    // MARK: - Eney Wand (Option + W) Text & Privacy Tools
    public func runWandAction(_ action: String) {
        let source = wandInputText.isEmpty ? (NSPasteboard.general.string(forType: .string) ?? activeContext.screenOCRText) : wandInputText
        guard !source.isEmpty else {
            wandOutputText = "Lütfen önce bir metin girin veya panoya kopyalayın."
            return
        }
        wandInputText = source

        switch action {
        case "mask_pii":
            var masked = source
            let patterns: [(String, String)] = [
                ("TR\\d{2}\\s?\\d{4}\\s?\\d{4}\\s?\\d{4}\\s?\\d{4}\\s?\\d{4}\\s?\\d{2}", "[GİZLİ_IBAN]"),
                ("\\b(?:\\d[ -]*?){13,16}\\b", "[GİZLİ_KART_NO]"),
                ("[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}", "[GİZLİ_EPOSTA]"),
                ("sk-[A-Za-z0-9_-]{16,}", "[GİZLİ_API_ANAHTARI]")
            ]
            for (pattern, replacement) in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let range = NSRange(masked.startIndex..<masked.endIndex, in: masked)
                    masked = regex.stringByReplacingMatches(in: masked, range: range, withTemplate: replacement)
                }
            }
            wandOutputText = masked

        case "summarize":
            let sentences = source.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.count > 12 }
            let top = sentences.prefix(3).map { "• \($0)." }.joined(separator: "\n")
            wandOutputText = top.isEmpty ? source : "📌 **Hızlı Özet:**\n\(top)"

        case "polish":
            Task {
                if selectedModel != "apple-on-device-nl",
                   let res = await callOllamaChat(
                    model: selectedModel,
                    system: "Metni profesyonel, akıcı ve imla hatasız hale getir. Sadece düzeltilmiş metni döndür.",
                    user: source
                   ) {
                    self.wandOutputText = res
                } else {
                    let cleaned = source
                        .replacingOccurrences(of: "  ", with: " ")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    self.wandOutputText = cleaned.prefix(1).uppercased() + cleaned.dropFirst()
                }
            }

        default:
            break
        }
    }

    public func toggleWandFloatingPanel() {
        toggleSpotlightOverlay()
    }
}
