import SwiftUI
import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Vision
import PDFKit
import CryptoKit

// MARK: - 1. Custom Key-Capable Floating Panel (Ensures First-Click & Hover Always Work Over Finder)
public final class NashiFloatingPanel: NSPanel {
    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { false }
}

// MARK: - 2. Nashi Radial Wheel Ring Modes (orkunisitmak/nashi-app Modifier Architecture)
public enum NashiWheelMode: String, CaseIterable, Identifiable {
    case shiftConvert = "⇧ Shift • Dönüştür"
    case commandTools = "⌘ Cmd • AI & Araçlar"
    case controlActions = "⌃ Ctrl • Sistem & Ada"

    public var id: String { rawValue }

    public var shortTitle: String {
        switch self {
        case .shiftConvert: return "⇧ Dönüştür"
        case .commandTools: return "⌘ AI Araçlar"
        case .controlActions: return "⌃ Sistem & Ada"
        }
    }

    public var subtitle: String {
        switch self {
        case .shiftConvert: return "Hızlı Format & Arşiv Dönüştürme Çarkı"
        case .commandTools: return "Vision AI Arka Plan Silici, OCR, Kırpma & QR"
        case .controlActions: return "Dinamik Ada Rafı, Eney AI, AirDrop & SHA-256"
        }
    }

    public var badgeColor: Color {
        switch self {
        case .shiftConvert: return .orange
        case .commandTools: return .purple
        case .controlActions: return .cyan
        }
    }

    public func nextMode() -> NashiWheelMode {
        switch self {
        case .shiftConvert: return .commandTools
        case .commandTools: return .controlActions
        case .controlActions: return .shiftConvert
        }
    }
}

// MARK: - 3. Custom Visual Themes for Redesigned Nashi Radial Wheel UI
public enum NashiWheelTheme: String, CaseIterable, Identifiable {
    case nashiPearNeon = "🍐 Nashi Gold & Emerald"
    case cyberGlass = "🔮 Cyber Glass Neon"
    case tangerineSolar = "🍊 Tangerine Solar"
    case oledMatrix = "🌑 OLED Matrix Green"

    public var id: String { rawValue }

    public var primaryColor: Color {
        switch self {
        case .nashiPearNeon: return Color(red: 0.96, green: 0.78, blue: 0.22)
        case .cyberGlass: return .cyan
        case .tangerineSolar: return .orange
        case .oledMatrix: return .green
        }
    }

    public var secondaryColor: Color {
        switch self {
        case .nashiPearNeon: return .mint
        case .cyberGlass: return .purple
        case .tangerineSolar: return .pink
        case .oledMatrix: return .teal
        }
    }
}

// MARK: - 4. Radial Wheel Slice Item Model
public struct NashiWheelSlice: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let icon: String
    public let accent: Color
    public let actionKey: String
}

// MARK: - 5. Geometric Donut Sector Shape for 360° Radial Pie Slices
public struct RadialSliceSectorShape: Shape {
    public let startAngle: Angle
    public let endAngle: Angle
    public let innerRadius: CGFloat
    public let outerRadius: CGFloat

    public func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - 6. Redesigned Interactive Nashi 360° Radial Action Wheel View (With Exact Polar Math Hit-Testing!)
public struct NashiRadialWheelView: View {
    @ObservedObject var manager: NashiToolkitManager
    public var isFloatingPopup: Bool = false

    @State private var hoveredSliceIndex: Int? = nil
    @State private var isCenterHubHovered: Bool = false

    private let wheelSize: CGFloat = 370
    private let outerRadius: CGFloat = 160
    private let innerRadius: CGFloat = 68

    public var body: some View {
        let slices = manager.slices(for: manager.activeWheelMode)

        VStack(spacing: 10) {
            // Top Mode Switcher Bar (Shift / Command / Control) — Compact & Always Inside Screen
            HStack(spacing: 6) {
                ForEach(NashiWheelMode.allCases) { mode in
                    let isSelected = (manager.activeWheelMode == mode)
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.76)) {
                            manager.activeWheelMode = mode
                            hoveredSliceIndex = nil
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(mode.badgeColor)
                                .frame(width: 6, height: 6)
                            Text(mode.shortTitle)
                                .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isSelected ? mode.badgeColor.opacity(0.35) : Color.white.opacity(0.07))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(isSelected ? mode.badgeColor : Color.white.opacity(0.14), lineWidth: isSelected ? 1.5 : 0.8)
                        )
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.75))
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                if isFloatingPopup {
                    Button {
                        manager.dismissRadialWheelPopup()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(
                Capsule()
                    .fill(Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.95))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
            )
            .shadow(color: .black.opacity(0.5), radius: 10)

            // 360° Interactive Radial Donut Wheel with Polar Coordinate Hit-Testing
            ZStack {
                // Ambient Outer Neon Halo
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                manager.activeWheelMode.badgeColor.opacity(0.24),
                                manager.wheelTheme.primaryColor.opacity(0.10),
                                .clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 185
                        )
                    )
                    .frame(width: wheelSize, height: wheelSize)
                    .allowsHitTesting(false)

                // Dark Frosted Base Ring
                Circle()
                    .fill(Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.94))
                    .frame(width: outerRadius * 2 + 12, height: outerRadius * 2 + 12)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        manager.activeWheelMode.badgeColor.opacity(0.7),
                                        manager.wheelTheme.primaryColor.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.6
                            )
                    )
                    .shadow(color: .black.opacity(0.7), radius: 22, y: 10)

                // 6 Visual Pie Sector Slices
                ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                    let count = Double(slices.count)
                    let stepDegrees = 360.0 / count
                    let startDeg = Double(index) * stepDegrees - 90.0 + 2.2
                    let endDeg = Double(index + 1) * stepDegrees - 90.0 - 2.2
                    let midRad = ((startDeg + endDeg) / 2.0) * (.pi / 180.0)
                    let isHovered = (hoveredSliceIndex == index)

                    let labelRadius: CGFloat = (innerRadius + outerRadius) / 2.0
                    let labelX = cos(midRad) * labelRadius
                    let labelY = sin(midRad) * labelRadius

                    ZStack {
                        RadialSliceSectorShape(
                            startAngle: .degrees(startDeg),
                            endAngle: .degrees(endDeg),
                            innerRadius: innerRadius,
                            outerRadius: isHovered ? outerRadius + 9 : outerRadius
                        )
                        .fill(
                            LinearGradient(
                                colors: isHovered
                                    ? [slice.accent.opacity(0.62), manager.wheelTheme.primaryColor.opacity(0.38)]
                                    : [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RadialSliceSectorShape(
                                startAngle: .degrees(startDeg),
                                endAngle: .degrees(endDeg),
                                innerRadius: innerRadius,
                                outerRadius: isHovered ? outerRadius + 9 : outerRadius
                            )
                            .stroke(
                                isHovered ? slice.accent : Color.white.opacity(0.13),
                                lineWidth: isHovered ? 2.2 : 1.0
                            )
                        )

                        // Slice Icon & Title Positioned at Polar Midpoint
                        VStack(spacing: 3) {
                            Image(systemName: slice.icon)
                                .font(.system(size: isHovered ? 21 : 17, weight: .bold))
                                .foregroundStyle(isHovered ? .white : slice.accent)
                                .shadow(color: isHovered ? slice.accent.opacity(0.9) : .clear, radius: 6)

                            Text(slice.title)
                                .font(.system(size: isHovered ? 11.5 : 11, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)

                            Text(slice.subtitle)
                                .font(.system(size: 8.5, weight: .medium))
                                .foregroundStyle(.white.opacity(isHovered ? 0.92 : 0.65))
                                .lineLimit(1)
                        }
                        .offset(x: labelX, y: labelY)
                    }
                    .frame(width: wheelSize, height: wheelSize)
                    .allowsHitTesting(false)
                }

                // Center File Hub Core (Click Center Hub to Cycle Mode: Shift -> Cmd -> Ctrl!)
                VStack(spacing: 3) {
                    if let fileIcon = manager.activeFileIcon {
                        Image(nsImage: fileIcon)
                            .resizable()
                            .frame(width: 32, height: 32)
                    } else {
                        Image(systemName: "doc.viewfinder.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(manager.wheelTheme.primaryColor)
                    }

                    Text(manager.activeFileDisplayName)
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .frame(maxWidth: 105)

                    if let idx = hoveredSliceIndex, idx < slices.count {
                        let hoveredSlice = slices[idx]
                        Text("⚡ \(hoveredSlice.title)")
                            .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                            .foregroundStyle(hoveredSlice.accent)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(hoveredSlice.accent.opacity(0.20))
                            .clipShape(Capsule())
                    } else {
                        Text(isCenterHubHovered ? "🔄 Mod Değiştir" : manager.activeWheelMode.shortTitle)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(manager.activeWheelMode.badgeColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(manager.activeWheelMode.badgeColor.opacity(0.16))
                            .clipShape(Capsule())
                    }
                }
                .frame(width: innerRadius * 1.88, height: innerRadius * 1.88)
                .background(
                    Circle()
                        .fill(Color(red: 0.08, green: 0.09, blue: 0.14))
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [manager.activeWheelMode.badgeColor, manager.wheelTheme.primaryColor],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: isCenterHubHovered ? 3.0 : 2.0
                                )
                        )
                )
                .scaleEffect(isCenterHubHovered ? 1.05 : 1.0)
                .shadow(color: manager.activeWheelMode.badgeColor.opacity(0.4), radius: 10)
                .allowsHitTesting(false)
            }
            .frame(width: wheelSize, height: wheelSize)
            .contentShape(Circle())
            // Exact Polar Coordinate Hover Tracker (Zero ZStack Overlap Bugs!)
            .onContinuousHover { phase in
                switch phase {
                case .active(let pt):
                    updatePolarHover(at: pt, sliceCount: slices.count)
                case .ended:
                    withAnimation(.easeOut(duration: 0.15)) {
                        hoveredSliceIndex = nil
                        isCenterHubHovered = false
                    }
                }
            }
            // Exact Polar Coordinate Click / Tap Handler
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        updatePolarHover(at: value.location, sliceCount: slices.count)
                    }
                    .onEnded { value in
                        handlePolarTap(at: value.location, slices: slices)
                    }
            )

            // Bottom Status Pill
            Text(manager.conversionStatus)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.95))
                        .overlay(Capsule().strokeBorder(manager.activeWheelMode.badgeColor.opacity(0.5), lineWidth: 1))
                )
        }
        .padding(8)
    }

    // MARK: - Polar Geometry Calculator (atan2 + hypot)
    private func updatePolarHover(at point: CGPoint, sliceCount: Int) {
        let center = CGPoint(x: wheelSize / 2.0, y: wheelSize / 2.0)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let dist = hypot(dx, dy)

        if dist < innerRadius {
            if !isCenterHubHovered || hoveredSliceIndex != nil {
                withAnimation(.spring(response: 0.20, dampingFraction: 0.75)) {
                    isCenterHubHovered = true
                    hoveredSliceIndex = nil
                }
            }
        } else if dist >= innerRadius && dist <= outerRadius + 16 {
            var deg = atan2(dy, dx) * 180.0 / .pi + 90.0
            if deg < 0 { deg += 360.0 }
            let step = 360.0 / Double(max(1, sliceCount))
            let idx = Int(deg / step) % max(1, sliceCount)
            if hoveredSliceIndex != idx || isCenterHubHovered {
                withAnimation(.spring(response: 0.20, dampingFraction: 0.75)) {
                    hoveredSliceIndex = idx
                    isCenterHubHovered = false
                }
            }
        } else {
            if hoveredSliceIndex != nil || isCenterHubHovered {
                withAnimation(.easeOut(duration: 0.15)) {
                    hoveredSliceIndex = nil
                    isCenterHubHovered = false
                }
            }
        }
    }

    private func handlePolarTap(at point: CGPoint, slices: [NashiWheelSlice]) {
        let center = CGPoint(x: wheelSize / 2.0, y: wheelSize / 2.0)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let dist = hypot(dx, dy)

        if dist < innerRadius {
            // Clicking the center hub cycles between Shift (Convert) -> Cmd (AI Tools) -> Ctrl (System & Notch)!
            withAnimation(.spring(response: 0.26, dampingFraction: 0.75)) {
                manager.activeWheelMode = manager.activeWheelMode.nextMode()
                hoveredSliceIndex = nil
            }
            return
        }

        if dist >= innerRadius && dist <= outerRadius + 18 {
            var deg = atan2(dy, dx) * 180.0 / .pi + 90.0
            if deg < 0 { deg += 360.0 }
            let step = 360.0 / Double(max(1, slices.count))
            let idx = Int(deg / step) % max(1, slices.count)
            if idx >= 0 && idx < slices.count {
                manager.executeRadialSlice(slices[idx])
            }
        }
    }
}

// MARK: - 7. CGEventTap Callback to Swallow System Right-Click Context Menu on Shift+RightClick!
private func nashiContextMenuBlockerCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = NashiToolkitManager.sharedEventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    let flags = event.flags
    let isShiftHeld = flags.contains(.maskShift)

    // When user holds SHIFT and Right-Clicks (or Control+Clicks):
    // 1. We swallow rightMouseDown & rightMouseUp so macOS Finder NEVER opens its ugly system context menu!
    // 2. On rightMouseDown, we inject a quick left-click at that point so Finder selects the file under the cursor, then open Nashi Wheel!
    if isShiftHeld && (type == .rightMouseDown || type == .rightMouseUp) {
        if type == .rightMouseDown {
            let loc = event.location
            // Post a clean left-click without Shift so Finder selects the clicked file icon without opening any menu
            if let leftDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: loc, mouseButton: .left),
               let leftUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: loc, mouseButton: .left) {
                leftDown.flags = []
                leftUp.flags = []
                leftDown.post(tap: .cghidEventTap)
                leftUp.post(tap: .cghidEventTap)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
                Task { @MainActor in
                    NashiToolkitManager.shared.captureFinderSelectionOrDragPasteboard()
                    NashiToolkitManager.shared.showRadialWheelAtCursor()
                }
            }
        }
        // Return nil to COMPLETELY BLOCK the system right-click context menu!
        return nil
    }

    return Unmanaged.passUnretained(event)
}

// MARK: - 8. NashiToolkitManager (Shift+Click Finder Monitor + Context Menu Blocker + Radial Wheel)
@MainActor
public final class NashiToolkitManager: ObservableObject {
    public static let shared = NashiToolkitManager()
    nonisolated(unsafe) public static var sharedEventTap: CFMachPort?

    // Shift + Click / Shift + Drag Radial Wheel State
    @Published public var isShiftClickWheelEnabled: Bool = true
    @Published public var blockSystemContextMenuOnShiftRightClick: Bool = true {
        didSet {
            if blockSystemContextMenuOnShiftRightClick {
                startContextMenuBlockerTap()
            } else {
                stopContextMenuBlockerTap()
            }
        }
    }
    @Published public var activeWheelMode: NashiWheelMode = .shiftConvert
    @Published public var wheelTheme: NashiWheelTheme = .nashiPearNeon
    @Published public var isWheelPopupVisible: Bool = false
    @Published public var totalWheelTriggers: Int = 0

    // Image & File Converter State
    @Published public var selectedFilePath: String = ""
    @Published public var targetFormat: String = "PNG"
    @Published public var jpegQuality: Double = 0.85
    @Published public var conversionStatus: String = "🍐 Finder'da dosyaya ⇧ Shift + Sağ Tık veya ⇧ Shift + Sürükle yapın!"
    @Published public var lastOutputFilePath: String = ""

    // QR Code Reader & Generator State
    @Published public var qrInputText: String = "https://github.com/orkunisitmak/nashi-app"
    @Published public var decodedQRText: String = ""
    @Published public var generatedQRImage: NSImage?

    // Web Media Downloader State
    @Published public var mediaURLString: String = ""
    @Published public var downloadStatus: String = "Hazır (yt-dlp / doğrudan medya indirici)"
    @Published public var isDownloading: Bool = false

    // Native macOS Finder Right-Click Menu (NSServices + ~/Library/Services Quick Actions) State
    @Published public var isFinderContextMenuInstalled: Bool = false
    @Published public var finderContextMenuStatus: String = "macOS Sağ Tık Menüsü & Hızlı Eylemler entegrasyonu hazır."

    private let ciContext = CIContext()
    private var radialWheelPanel: NashiFloatingPanel?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var globalFlagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var runLoopSource: CFRunLoopSource?
    private var lastShiftTriggerTimestamp: TimeInterval = 0

    private init() {
        generateQRCode()
        seedDefaultSampleFileIfNeeded()
        startShiftClickFinderMonitor()
        startContextMenuBlockerTap()
        registerNativeFinderServicesProvider()
    }

    // MARK: - Active File Metadata Helpers for Center Wheel Hub
    public var activeFileDisplayName: String {
        guard !selectedFilePath.isEmpty else { return "Dosya Seçilmedi" }
        return URL(fileURLWithPath: selectedFilePath).lastPathComponent
    }

    public var activeFileBadgeText: String {
        guard !selectedFilePath.isEmpty else { return "⇧ + Tıkla" }
        let url = URL(fileURLWithPath: selectedFilePath)
        let ext = url.pathExtension.uppercased()
        if let attrs = try? FileManager.default.attributesOfItem(atPath: selectedFilePath),
           let size = attrs[.size] as? Int64 {
            let kb = Double(size) / 1024.0
            if kb > 1024 {
                return "\(ext) • \(String(format: "%.1f MB", kb / 1024.0))"
            }
            return "\(ext) • \(String(format: "%.0f KB", max(1, kb)))"
        }
        return ext.isEmpty ? "DOSYA" : ext
    }

    public var activeFileIcon: NSImage? {
        guard !selectedFilePath.isEmpty, FileManager.default.fileExists(atPath: selectedFilePath) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: selectedFilePath)
    }

    private func seedDefaultSampleFileIfNeeded() {
        let downloads = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
        if let items = try? FileManager.default.contentsOfDirectory(at: downloads, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]),
           let firstFile = items.first(where: { !$0.hasDirectoryPath }) {
            selectedFilePath = firstFile.path
        }
    }

    // MARK: - Slices Definition for Each Ring Mode (Shift / Command / Control)
    public func slices(for mode: NashiWheelMode) -> [NashiWheelSlice] {
        switch mode {
        case .shiftConvert:
            return [
                NashiWheelSlice(id: "conv_png", title: "PNG", subtitle: "Kayıpsız Görsel", icon: "photo.fill", accent: .cyan, actionKey: "convert:PNG"),
                NashiWheelSlice(id: "conv_jpg", title: "JPEG", subtitle: "%85 Optimize", icon: "camera.aperture", accent: .orange, actionKey: "convert:JPEG"),
                NashiWheelSlice(id: "conv_pdf", title: "PDF", subtitle: "Belgeye Çevir", icon: "doc.richtext.fill", accent: .red, actionKey: "convert:PDF"),
                NashiWheelSlice(id: "conv_tiff", title: "TIFF", subtitle: "Baskı Kalitesi", icon: "square.stack.3d.up.fill", accent: .purple, actionKey: "convert:TIFF"),
                NashiWheelSlice(id: "conv_zip", title: "ZIP Arşiv", subtitle: "Anında Sıkıştır", icon: "doc.zipper", accent: .yellow, actionKey: "zip_archive"),
                NashiWheelSlice(id: "conv_bmp", title: "BMP", subtitle: "Ham Bitmap", icon: "cpu.fill", accent: .mint, actionKey: "convert:BMP")
            ]
        case .commandTools:
            return [
                NashiWheelSlice(id: "tool_nobg", title: "Arka Plan Sil", subtitle: "Apple Vision AI", icon: "person.crop.rectangle.badge.plus", accent: .purple, actionKey: "remove_bg"),
                NashiWheelSlice(id: "tool_ocr", title: "Vision OCR", subtitle: "Metni Kopyala", icon: "text.viewfinder", accent: .cyan, actionKey: "ocr_extract"),
                NashiWheelSlice(id: "tool_qr", title: "QR Çöz / Üret", subtitle: "Hızlı Karekod", icon: "qrcode.viewfinder", accent: .green, actionKey: "qr_scan"),
                NashiWheelSlice(id: "tool_resize50", title: "%50 Küçült", subtitle: "Hızlı Boyutlandır", icon: "arrow.down.right.and.arrow.up.left", accent: .orange, actionKey: "resize_50"),
                NashiWheelSlice(id: "tool_crop1x1", title: "1:1 Kare Kırp", subtitle: "Merkezden Kırp", icon: "crop", accent: .pink, actionKey: "crop_square"),
                NashiWheelSlice(id: "tool_exif", title: "EXIF Temizle", subtitle: "Gizlilik Koruması", icon: "eye.slash.fill", accent: .yellow, actionKey: "strip_exif")
            ]
        case .controlActions:
            return [
                NashiWheelSlice(id: "act_notch", title: "Dinamik Ada", subtitle: "Çentik Rafına At", icon: "rectangle.topthird.inset.filled", accent: .pink, actionKey: "send_to_notch"),
                NashiWheelSlice(id: "act_eney", title: "Eney AI Analiz", subtitle: "Yapay Zekaya Sor", icon: "wand.and.stars", accent: .purple, actionKey: "send_to_eney"),
                NashiWheelSlice(id: "act_sha256", title: "SHA-256", subtitle: "Hash Kopyala", icon: "number.square.fill", accent: .cyan, actionKey: "copy_sha256"),
                NashiWheelSlice(id: "act_path", title: "Yolu Kopyala", subtitle: "POSIX Path", icon: "doc.on.doc.fill", accent: .green, actionKey: "copy_path"),
                NashiWheelSlice(id: "act_airdrop", title: "AirDrop", subtitle: "Anında Gönder", icon: "paperplane.fill", accent: .blue, actionKey: "share_airdrop"),
                NashiWheelSlice(id: "act_reveal", title: "Finder'da Göster", subtitle: "Klasörü Aç", icon: "folder.fill", accent: .orange, actionKey: "reveal_finder")
            ]
        }
    }

    // MARK: - 1A. Active CGEventTap to Swallow Finder System Right-Click Context Menu
    public func startContextMenuBlockerTap() {
        stopContextMenuBlockerTap()
        guard blockSystemContextMenuOnShiftRightClick else { return }

        let mask = (1 << CGEventType.rightMouseDown.rawValue) | (1 << CGEventType.rightMouseUp.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: nashiContextMenuBlockerCallback,
            userInfo: nil
        ) else {
            return
        }

        Self.sharedEventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    public func stopContextMenuBlockerTap() {
        if let tap = Self.sharedEventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
        }
        Self.sharedEventTap = nil
        runLoopSource = nil
    }

    // MARK: - 1B. Global Finder Shift + Drag / Shift + Click & Keyboard Mode Switcher
    public func startShiftClickFinderMonitor() {
        stopShiftClickFinderMonitor()

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .leftMouseDragged]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleIncomingMouseEvent(event)
            }
        }

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown, .keyDown, .scrollWheel]) { [weak self] event in
            guard let self = self else { return event }
            if event.type == .rightMouseDown && event.modifierFlags.contains(.shift) {
                Task { @MainActor in
                    self.showRadialWheelAtCursor()
                }
                return nil // Swallow local right-click menu too!
            }
            if self.isWheelPopupVisible {
                if event.type == .keyDown {
                    if event.keyCode == 53 { // ESC closes wheel
                        Task { @MainActor in self.dismissRadialWheelPopup() }
                        return nil
                    } else if event.keyCode == 48 { // Tab key cycles wheel mode!
                        Task { @MainActor in
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.76)) {
                                self.activeWheelMode = self.activeWheelMode.nextMode()
                            }
                        }
                        return nil
                    } else if event.charactersIgnoringModifiers == "1" {
                        Task { @MainActor in self.activeWheelMode = .shiftConvert }
                        return nil
                    } else if event.charactersIgnoringModifiers == "2" {
                        Task { @MainActor in self.activeWheelMode = .commandTools }
                        return nil
                    } else if event.charactersIgnoringModifiers == "3" {
                        Task { @MainActor in self.activeWheelMode = .controlActions }
                        return nil
                    }
                }
            }
            return event
        }

        // Live Modifier Key Switching (Pressing Command or Control switches wheel mode without snapping back when released!)
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleModifierFlagsChanged(event.modifierFlags)
            }
        }
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleModifierFlagsChanged(event.modifierFlags)
            }
            return event
        }
    }

    public func stopShiftClickFinderMonitor() {
        if let globalMouseMonitor { NSEvent.removeMonitor(globalMouseMonitor) }
        if let localMouseMonitor { NSEvent.removeMonitor(localMouseMonitor) }
        if let globalFlagsMonitor { NSEvent.removeMonitor(globalFlagsMonitor) }
        if let localFlagsMonitor { NSEvent.removeMonitor(localFlagsMonitor) }
        globalMouseMonitor = nil
        localMouseMonitor = nil
        globalFlagsMonitor = nil
        localFlagsMonitor = nil
    }

    private func handleModifierFlagsChanged(_ flags: NSEvent.ModifierFlags) {
        guard isWheelPopupVisible else { return }
        if flags.contains(.command) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
                activeWheelMode = .commandTools
            }
        } else if flags.contains(.control) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
                activeWheelMode = .controlActions
            }
        } else if flags.contains(.shift) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
                activeWheelMode = .shiftConvert
            }
        }
    }

    private func handleIncomingMouseEvent(_ event: NSEvent) {
        guard isShiftClickWheelEnabled else { return }
        let flags = event.modifierFlags

        // Close wheel if user clicks outside the wheel panel without holding Shift
        if isWheelPopupVisible, let panel = radialWheelPanel {
            let mouseLoc = NSEvent.mouseLocation
            if !panel.frame.contains(mouseLoc) && !flags.contains(.shift) {
                dismissRadialWheelPopup()
                return
            }
            // If clicking inside the wheel panel, let the wheel handle the click!
            if panel.frame.contains(mouseLoc) {
                return
            }
        }

        guard flags.contains(.shift) else { return }

        let now = CACurrentMediaTime()
        guard now - lastShiftTriggerTimestamp > 0.45 else { return }

        let frontBundle = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        let isFinderFront = (frontBundle == "com.apple.finder")

        // Trigger in Finder on Shift + Drag or Shift + Left Click or Shift + Right Click
        if (isFinderFront && (event.type == .leftMouseDragged || event.type == .leftMouseDown)) ||
           event.type == .rightMouseDown {
            lastShiftTriggerTimestamp = now
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
                guard let self = self else { return }
                self.captureFinderSelectionOrDragPasteboard()
                self.showRadialWheelAtCursor()
            }
        }
    }

    // MARK: - 2. Query Finder Selected File via AppleScript & Drag Pasteboard
    public func captureFinderSelectionOrDragPasteboard() {
        // 1. Query macOS Finder Selection via NSAppleScript first (most accurate for clicked icon)
        let scriptSource = """
        tell application "Finder"
            if selection is not {} then
                set selectedItem to item 1 of (get selection)
                return POSIX path of (selectedItem as alias)
            end if
        end tell
        """
        if let script = NSAppleScript(source: scriptSource) {
            var errorDict: NSDictionary?
            let descriptor = script.executeAndReturnError(&errorDict)
            if let path = descriptor.stringValue, !path.isEmpty {
                let cleanPath = path.hasSuffix("/") && path.count > 1 ? String(path.dropLast()) : path
                selectedFilePath = cleanPath
                conversionStatus = "🍐 Finder Seçimi Yakalandı: \(URL(fileURLWithPath: cleanPath).lastPathComponent)"
                return
            }
        }

        // 2. Fallback: Check Drag Pasteboard (if user Shift + Dragged a file)
        let dragPB = NSPasteboard(name: .drag)
        if let urls = dragPB.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let first = urls.first, first.isFileURL {
            selectedFilePath = first.path
            conversionStatus = "🍐 Finder Sürüklemesi Yakalandı: \(first.lastPathComponent)"
            return
        }
    }

    // MARK: - 3. Spawn Floating Nashi Radial Wheel Popup Centered at Mouse Cursor (Clamped to Screen Bounds!)
    public func showRadialWheelAtCursor() {
        let mouseLoc = NSEvent.mouseLocation
        let panelWidth: CGFloat = 430
        let panelHeight: CGFloat = 470

        var originX = mouseLoc.x - (panelWidth / 2.0)
        var originY = mouseLoc.y - (panelHeight / 2.0)

        // Clamp to visible screen bounds so the top mode bar and right slices NEVER go off-screen or behind the Dock!
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) }) ?? NSScreen.main {
            let visible = screen.visibleFrame
            let margin: CGFloat = 14
            originX = max(visible.minX + margin, min(originX, visible.maxX - panelWidth - margin))
            originY = max(visible.minY + margin, min(originY, visible.maxY - panelHeight - margin))
        }

        let frame = NSRect(x: originX, y: originY, width: panelWidth, height: panelHeight)

        if radialWheelPanel == nil {
            let panel = NashiFloatingPanel(
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
                rootView: NashiRadialWheelView(manager: self, isFloatingPopup: true)
            )
            radialWheelPanel = panel
        } else {
            radialWheelPanel?.setFrame(frame, display: true)
        }

        // Activate and make key so first click on any mode button or radial slice works immediately without Finder intercepting!
        NSApp.activate(ignoringOtherApps: true)
        radialWheelPanel?.makeKeyAndOrderFront(nil)
        isWheelPopupVisible = true
        totalWheelTriggers += 1
    }

    public func dismissRadialWheelPopup() {
        radialWheelPanel?.orderOut(nil)
        isWheelPopupVisible = false
    }

    // MARK: - 4. Execute Clicked Radial Wheel Slice Action
    public func executeRadialSlice(_ slice: NashiWheelSlice) {
        let key = slice.actionKey
        if key.hasPrefix("convert:") {
            let fmt = key.replacingOccurrences(of: "convert:", with: "")
            targetFormat = fmt
            convertSelectedFile()
        } else {
            switch key {
            case "zip_archive":
                createZipArchiveOfSelectedFile()
            case "remove_bg":
                removeBackgroundFromSelectedImage()
            case "ocr_extract":
                extractTextViaVisionOCR()
            case "qr_scan":
                if !selectedFilePath.isEmpty {
                    readQRCode(from: URL(fileURLWithPath: selectedFilePath))
                    conversionStatus = "🔳 QR Sonucu: \(decodedQRText)"
                }
            case "resize_50":
                resizeSelectedImage(scaleFactor: 0.5)
            case "crop_square":
                cropSelectedImageToSquare()
            case "strip_exif":
                stripEXIFMetadata()
            case "send_to_notch":
                sendSelectedFileToDynamicIslandShelf()
            case "send_to_eney":
                sendSelectedFileToEneyAI()
            case "copy_sha256":
                copySHA256OfSelectedFile()
            case "copy_path":
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(selectedFilePath, forType: .string)
                conversionStatus = "📋 Dosya yolu panoya kopyalandı: \(selectedFilePath)"
            case "share_airdrop":
                shareSelectedFileViaAirDrop()
            case "reveal_finder":
                if !selectedFilePath.isEmpty {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: selectedFilePath)])
                    conversionStatus = "📂 Finder'da gösterildi: \(activeFileDisplayName)"
                }
            default:
                break
            }
        }

        if isWheelPopupVisible {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.dismissRadialWheelPopup()
            }
        }
    }

    // MARK: - 5. Extended Nashi Wheel Actions (ZIP, OCR, Resize, 1:1 Crop, EXIF Strip, Dynamic Island, SHA-256)
    public func createZipArchiveOfSelectedFile() {
        guard !selectedFilePath.isEmpty else {
            conversionStatus = "⚠️ ZIP için önce bir dosya seçin."
            return
        }
        let inputURL = URL(fileURLWithPath: selectedFilePath)
        let outURL = inputURL.deletingPathExtension().appendingPathExtension("zip")
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        proc.arguments = ["-c", "-k", "--sequesterRsrc", inputURL.path, outURL.path]
        do {
            try proc.run()
            proc.waitUntilExit()
            lastOutputFilePath = outURL.path
            conversionStatus = "🗜️ ZIP Arşivi oluşturuldu: \(outURL.lastPathComponent)"
        } catch {
            conversionStatus = "⚠️ ZIP oluşturma hatası: \(error.localizedDescription)"
        }
    }

    public func extractTextViaVisionOCR() {
        guard !selectedFilePath.isEmpty else {
            conversionStatus = "⚠️ OCR için bir görsel seçin."
            return
        }
        let inputURL = URL(fileURLWithPath: selectedFilePath)
        guard let ciImage = CIImage(contentsOf: inputURL) else {
            conversionStatus = "⚠️ OCR için görsel okunamadı."
            return
        }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        try? handler.perform([request])
        let recognized = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
        if recognized.isEmpty {
            conversionStatus = "⚠️ Görselde metin bulunamadı."
        } else {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(recognized, forType: .string)
            conversionStatus = "📝 Vision OCR ile \(recognized.count) karakter panoya kopyalandı!"
        }
    }

    public func resizeSelectedImage(scaleFactor: CGFloat) {
        guard !selectedFilePath.isEmpty,
              let ciImage = CIImage(contentsOf: URL(fileURLWithPath: selectedFilePath)) else {
            conversionStatus = "⚠️ Boyutlandırmak için bir görsel seçin."
            return
        }
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
        guard let cgImage = ciContext.createCGImage(scaled, from: scaled.extent) else { return }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        if let data = rep.representation(using: .png, properties: [:]) {
            let inputURL = URL(fileURLWithPath: selectedFilePath)
            let outURL = inputURL.deletingPathExtension().appendingPathNameSuffix("_50pct").appendingPathExtension("png")
            try? data.write(to: outURL)
            lastOutputFilePath = outURL.path
            conversionStatus = "📐 %50 Küçültüldü (\(Int(scaled.extent.width))x\(Int(scaled.extent.height))): \(outURL.lastPathComponent)"
        }
    }

    public func cropSelectedImageToSquare() {
        guard !selectedFilePath.isEmpty,
              let ciImage = CIImage(contentsOf: URL(fileURLWithPath: selectedFilePath)) else {
            conversionStatus = "⚠️ Kırpmak için bir görsel seçin."
            return
        }
        let extent = ciImage.extent
        let side = min(extent.width, extent.height)
        let cropRect = CGRect(
            x: extent.origin.x + (extent.width - side) / 2.0,
            y: extent.origin.y + (extent.height - side) / 2.0,
            width: side,
            height: side
        )
        let cropped = ciImage.cropped(to: cropRect)
        guard let cgImage = ciContext.createCGImage(cropped, from: cropped.extent) else { return }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        if let data = rep.representation(using: .png, properties: [:]) {
            let inputURL = URL(fileURLWithPath: selectedFilePath)
            let outURL = inputURL.deletingPathExtension().appendingPathNameSuffix("_1x1").appendingPathExtension("png")
            try? data.write(to: outURL)
            lastOutputFilePath = outURL.path
            conversionStatus = "✂️ 1:1 Kare Kırpıldı (\(Int(side))x\(Int(side))): \(outURL.lastPathComponent)"
        }
    }

    public func stripEXIFMetadata() {
        guard !selectedFilePath.isEmpty,
              let image = NSImage(contentsOfFile: selectedFilePath),
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let cleanData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.92]) else {
            conversionStatus = "⚠️ EXIF temizlemek için geçerli bir görsel seçin."
            return
        }
        let inputURL = URL(fileURLWithPath: selectedFilePath)
        let outURL = inputURL.deletingPathExtension().appendingPathNameSuffix("_clean").appendingPathExtension("jpg")
        try? cleanData.write(to: outURL)
        lastOutputFilePath = outURL.path
        conversionStatus = "🛡️ Tüm GPS/EXIF gizlilik meta verileri temizlendi: \(outURL.lastPathComponent)"
    }

    public func sendSelectedFileToDynamicIslandShelf() {
        guard !selectedFilePath.isEmpty else { return }
        let url = URL(fileURLWithPath: selectedFilePath)
        let notch = DynamicIslandNotchManager.shared
        if !notch.shelfFiles.contains(url) {
            notch.shelfFiles.insert(url, at: 0)
        }
        notch.activeTab = .shelf
        notch.setExpanded(true)
        conversionStatus = "🏝️ '\(url.lastPathComponent)' Dinamik Ada Dosya Rafına eklendi!"
    }

    public func sendSelectedFileToEneyAI() {
        guard !selectedFilePath.isEmpty else { return }
        let name = URL(fileURLWithPath: selectedFilePath).lastPathComponent
        EneyAIAgentManager.shared.sendUserPrompt("Nashi Çarkından gönderilen '\(name)' (\(selectedFilePath)) dosyasını analiz et ve ne yapılabileceğini öner.")
        conversionStatus = "🤖 '\(name)' Eney AI asistanına gönderildi!"
    }

    public func copySHA256OfSelectedFile() {
        guard !selectedFilePath.isEmpty,
              let data = try? Data(contentsOf: URL(fileURLWithPath: selectedFilePath)) else {
            conversionStatus = "⚠️ SHA-256 için dosya okunamadı."
            return
        }
        let digest = SHA256.hash(data: data)
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(hex, forType: .string)
        conversionStatus = "🔒 SHA-256 kopyalandı: \(hex.prefix(16))..."
    }

    public func shareSelectedFileViaAirDrop() {
        guard !selectedFilePath.isEmpty else { return }
        let url = URL(fileURLWithPath: selectedFilePath)
        if let service = NSSharingService(named: .sendViaAirDrop) {
            service.perform(withItems: [url])
            conversionStatus = "📡 AirDrop paylaşım penceresi açıldı: \(url.lastPathComponent)"
        } else {
            conversionStatus = "⚠️ AirDrop servisi başlatılamadı."
        }
    }

    // MARK: - 6. Image Format Conversion (PNG / JPEG / TIFF / BMP / PDF)
    public func convertSelectedFile() {
        guard !selectedFilePath.isEmpty else {
            conversionStatus = "⚠️ Lütfen önce dönüştürülecek bir görsel seçin."
            return
        }
        let inputURL = URL(fileURLWithPath: selectedFilePath)
        guard let image = NSImage(contentsOf: inputURL),
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            conversionStatus = "⚠️ Görsel okunamadı (\(inputURL.lastPathComponent))."
            return
        }

        let baseURL = inputURL.deletingPathExtension()
        let outURL = baseURL.appendingPathExtension(targetFormat.lowercased())

        var outputData: Data?
        switch targetFormat.uppercased() {
        case "PNG":
            outputData = bitmap.representation(using: .png, properties: [:])
        case "JPG", "JPEG":
            outputData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: jpegQuality])
        case "TIFF":
            outputData = bitmap.representation(using: .tiff, properties: [:])
        case "BMP":
            outputData = bitmap.representation(using: .bmp, properties: [:])
        case "PDF":
            let pdf = PDFDocument()
            if let page = PDFPage(image: image) {
                pdf.insert(page, at: 0)
                outputData = pdf.dataRepresentation()
            }
        default:
            break
        }

        guard let data = outputData else {
            conversionStatus = "⚠️ Dönüştürme başarısız oldu."
            return
        }

        do {
            try data.write(to: outURL)
            lastOutputFilePath = outURL.path
            let kb = Double(data.count) / 1024.0
            conversionStatus = "✅ Dönüştürüldü: \(outURL.lastPathComponent) (\(String(format: "%.1f", kb)) KB)"
        } catch {
            conversionStatus = "⚠️ Yazma hatası: \(error.localizedDescription)"
        }
    }

    // MARK: - 7. Vision AI Foreground Cutout / Background Removal (Remove BG)
    public func removeBackgroundFromSelectedImage() {
        guard !selectedFilePath.isEmpty else {
            conversionStatus = "⚠️ Arka planını silmek için bir görsel seçin."
            return
        }
        let inputURL = URL(fileURLWithPath: selectedFilePath)
        guard let ciImage = CIImage(contentsOf: inputURL) else {
            conversionStatus = "⚠️ Görsel yüklenemedi."
            return
        }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        do {
            try handler.perform([request])
            guard let result = request.results?.first else {
                conversionStatus = "⚠️ Ön plan nesnesi tespit edilemedi."
                return
            }
            let maskBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
            let maskImage = CIImage(cvPixelBuffer: maskBuffer)

            let blendFilter = CIFilter.blendWithMask()
            blendFilter.inputImage = ciImage
            blendFilter.maskImage = maskImage
            blendFilter.backgroundImage = CIImage.empty()

            guard let outputCI = blendFilter.outputImage,
                  let cgImage = ciContext.createCGImage(outputCI, from: outputCI.extent) else {
                conversionStatus = "⚠️ Maskeleme oluşturulamadı."
                return
            }

            let rep = NSBitmapImageRep(cgImage: cgImage)
            if let pngData = rep.representation(using: .png, properties: [:]) {
                let outURL = inputURL.deletingPathExtension().appendingPathNameSuffix("_nobg").appendingPathExtension("png")
                try pngData.write(to: outURL)
                lastOutputFilePath = outURL.path
                conversionStatus = "✨ Arka plan Apple Vision AI ile silindi: \(outURL.lastPathComponent)"
            }
        } catch {
            conversionStatus = "⚠️ Vision AI arka plan silme hatası: \(error.localizedDescription)"
        }
    }

    // MARK: - 8. QR Code Generator & Reader
    public func generateQRCode() {
        guard !qrInputText.isEmpty else { return }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(qrInputText.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        if let cgImage = ciContext.createCGImage(scaled, from: scaled.extent) {
            generatedQRImage = NSImage(cgImage: cgImage, size: NSSize(width: 220, height: 220))
        }
    }

    public func readQRCode(from imageURL: URL) {
        guard let ciImage = CIImage(contentsOf: imageURL),
              let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: ciContext, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else {
            decodedQRText = "QR okunamadı."
            return
        }
        let features = detector.features(in: ciImage) as? [CIQRCodeFeature]
        let texts = features?.compactMap { $0.messageString } ?? []
        decodedQRText = texts.isEmpty ? "Görselde QR kod bulunamadı." : texts.joined(separator: "\n")
    }

    // MARK: - 9. Web Media Downloader (yt-dlp / Direct URL)
    public func downloadWebMedia() {
        let trimmed = mediaURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.scheme != nil else {
            downloadStatus = "⚠️ Geçerli bir http/https bağlantı girin."
            return
        }

        isDownloading = true
        downloadStatus = "⬇️ Medya indiriliyor..."
        let downloadsDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")

        Task {
            let ytdlpPath = "/opt/homebrew/bin/yt-dlp"
            if FileManager.default.isExecutableFile(atPath: ytdlpPath) {
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: ytdlpPath)
                proc.arguments = ["-P", downloadsDir.path, trimmed]
                try? proc.run()
                proc.waitUntilExit()
                self.isDownloading = false
                self.downloadStatus = proc.terminationStatus == 0
                    ? "✅ yt-dlp ile ~/Downloads klasörüne indirildi!"
                    : "⚠️ yt-dlp indirmeyi tamamlayamadı."
                return
            }

            // Direct URL Download fallback
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let filename = url.lastPathComponent.isEmpty ? "nashi_download_\(Int(Date().timeIntervalSince1970)).dat" : url.lastPathComponent
                let outURL = downloadsDir.appendingPathComponent(filename)
                try data.write(to: outURL)
                self.lastOutputFilePath = outURL.path
                self.downloadStatus = "✅ İndirildi: \(outURL.lastPathComponent) (\(data.count / 1024) KB)"
            } catch {
                self.downloadStatus = "⚠️ İndirme hatası: \(error.localizedDescription)"
            }
            self.isDownloading = false
        }
    }

    // MARK: - 10. Native macOS Finder Right-Click Context Menu & Quick Actions Installer (NSServices + ~/Library/Services)
    public func registerNativeFinderServicesProvider() {
        NSApp.servicesProvider = FinderContextMenuServiceProvider.shared
        NSAppleEventManager.shared().setEventHandler(
            FinderContextMenuServiceProvider.shared,
            andSelector: #selector(FinderContextMenuServiceProvider.handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
        let servicesDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Services")
        let markerWorkflow = servicesDir.appendingPathComponent("🍐 SuperMacHub — Nashi 360° Çarkında Aç.workflow")
        isFinderContextMenuInstalled = FileManager.default.fileExists(atPath: markerWorkflow.path)
        if !isFinderContextMenuInstalled {
            installNativeFinderRightClickQuickActions()
        }
    }

    public func installNativeFinderRightClickQuickActions() {
        let servicesDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Services")
        try? FileManager.default.createDirectory(at: servicesDir, withIntermediateDirectories: true)

        let workflows: [(name: String, actionKey: String, iconName: String, sendTypes: [String])] = [
            ("🍐 SuperMacHub — Nashi 360° Çarkında Aç", "nashi_wheel", "NSActionTemplate", ["public.item", "public.data", "public.content"]),
            ("✨ SuperMacHub — Arka Planı Sil (Vision AI)", "remove_bg", "NSActionTemplate", ["public.image", "public.item"]),
            ("🖼️ SuperMacHub — Kayıpsız PNG'ye Dönüştür", "convert_png", "NSActionTemplate", ["public.image", "public.item"]),
            ("📄 SuperMacHub — Anında PDF'e Dönüştür", "convert_pdf", "NSActionTemplate", ["public.image", "public.item"]),
            ("🏝️ SuperMacHub — Dinamik Ada Dosya Rafına Gönder", "send_to_notch", "NSActionTemplate", ["public.item", "public.data"]),
            ("🤖 SuperMacHub — Eney AI Spotlight ile Analiz Et", "eney_analyze", "NSActionTemplate", ["public.item", "public.data"])
        ]

        var installedCount = 0
        for wf in workflows {
            let wfBundleURL = servicesDir.appendingPathComponent("\(wf.name).workflow")
            let contentsURL = wfBundleURL.appendingPathComponent("Contents")
            try? FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)

            let infoPlistURL = contentsURL.appendingPathComponent("Info.plist")
            let wflowURL = contentsURL.appendingPathComponent("document.wflow")

            let sendTypesXML = wf.sendTypes.map { "<string>\($0)</string>" }.joined(separator: "\n\t\t\t\t")
            let infoPlistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>NSServices</key>
                <array>
                    <dict>
                        <key>NSBackgroundColorName</key>
                        <string>background</string>
                        <key>NSIconName</key>
                        <string>\(wf.iconName)</string>
                        <key>NSMenuItem</key>
                        <dict>
                            <key>default</key>
                            <string>\(wf.name)</string>
                        </dict>
                        <key>NSMessage</key>
                        <string>runWorkflowAsService</string>
                        <key>NSRequiredContext</key>
                        <dict>
                            <key>NSApplicationIdentifier</key>
                            <string>com.apple.finder</string>
                        </dict>
                        <key>NSSendFileTypes</key>
                        <array>
                            \(sendTypesXML)
                        </array>
                    </dict>
                </array>
            </dict>
            </plist>
            """

            let shellCommand = """
            for f in "$@"; do
                encoded=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$f")
                open "supermachub://action?type=\(wf.actionKey)&path=${encoded}"
            done
            """

            let wflowUUID1 = UUID().uuidString
            let wflowUUID2 = UUID().uuidString
            let documentWflowContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>AMApplicationBuild</key>
                <string>523</string>
                <key>AMApplicationVersion</key>
                <string>2.10</string>
                <key>AMDocumentVersion</key>
                <string>2</string>
                <key>actions</key>
                <array>
                    <dict>
                        <key>action</key>
                        <dict>
                            <key>AMAccepts</key>
                            <dict>
                                <key>Container</key>
                                <string>List</string>
                                <key>Optional</key>
                                <true/>
                                <key>Types</key>
                                <array>
                                    <string>com.apple.cocoa.string</string>
                                </array>
                            </dict>
                            <key>AMActionVersion</key>
                            <string>2.0.3</string>
                            <key>AMApplication</key>
                            <array>
                                <string>Automator</string>
                            </array>
                            <key>AMParameterProperties</key>
                            <dict>
                                <key>COMMAND_STRING</key>
                                <dict/>
                                <key>CheckedForUserDefaultShell</key>
                                <dict/>
                                <key>inputMethod</key>
                                <dict/>
                                <key>shell</key>
                                <dict/>
                                <key>source</key>
                                <dict/>
                            </dict>
                            <key>AMProvides</key>
                            <dict>
                                <key>Container</key>
                                <string>List</string>
                                <key>Types</key>
                                <array>
                                    <string>com.apple.cocoa.string</string>
                                </array>
                            </dict>
                            <key>ActionBundlePath</key>
                            <string>/System/Library/Automator/Run Shell Script.action</string>
                            <key>ActionName</key>
                            <string>Run Shell Script</string>
                            <key>ActionParameters</key>
                            <dict>
                                <key>COMMAND_STRING</key>
                                <string>\(shellCommand)</string>
                                <key>CheckedForUserDefaultShell</key>
                                <true/>
                                <key>inputMethod</key>
                                <integer>1</integer>
                                <key>shell</key>
                                <string>/bin/zsh</string>
                                <key>source</key>
                                <string></string>
                            </dict>
                            <key>BundleIdentifier</key>
                            <string>com.apple.RunShellScript</string>
                            <key>CFBundleVersion</key>
                            <string>2.0.3</string>
                            <key>CanShowSelectedItemsWhenRun</key>
                            <false/>
                            <key>CanShowWhenRun</key>
                            <true/>
                            <key>Category</key>
                            <array>
                                <string>AMCategoryUtilities</string>
                            </array>
                            <key>Class Name</key>
                            <string>RunShellScriptAction</string>
                            <key>InputUUID</key>
                            <string>\(wflowUUID1)</string>
                            <key>Keywords</key>
                            <array>
                                <string>Shell</string>
                                <string>Script</string>
                            </array>
                            <key>OutputUUID</key>
                            <string>\(wflowUUID2)</string>
                            <key>UUID</key>
                            <string>\(UUID().uuidString)</string>
                            <key>UnlocalizedApplications</key>
                            <array>
                                <string>Automator</string>
                            </array>
                        </dict>
                    </dict>
                </array>
                <key>connectors</key>
                <dict/>
                <key>workflowMetaData</key>
                <dict>
                    <key>applicationBundleID</key>
                    <string>com.apple.finder</string>
                    <key>applicationBundleIDsByPath</key>
                    <dict>
                        <key>/System/Library/CoreServices/Finder.app</key>
                        <string>com.apple.finder</string>
                    </dict>
                    <key>applicationPath</key>
                    <string>/System/Library/CoreServices/Finder.app</string>
                    <key>applicationPaths</key>
                    <array>
                        <string>/System/Library/CoreServices/Finder.app</string>
                    </array>
                    <key>inputTypeIdentifier</key>
                    <string>com.apple.Automator.fileSystemObject</string>
                    <key>outputTypeIdentifier</key>
                    <string>com.apple.Automator.nothing</string>
                    <key>presentationMode</key>
                    <integer>15</integer>
                    <key>processesInput</key>
                    <integer>0</integer>
                    <key>serviceApplicationGroupName</key>
                    <string>Finder</string>
                    <key>serviceApplicationPath</key>
                    <string>/System/Library/CoreServices/Finder.app</string>
                    <key>serviceInputTypeIdentifier</key>
                    <string>com.apple.Automator.fileSystemObject</string>
                    <key>serviceOutputTypeIdentifier</key>
                    <string>com.apple.Automator.nothing</string>
                    <key>serviceProcessesInput</key>
                    <integer>0</integer>
                    <key>systemImageName</key>
                    <string>NSActionTemplate</string>
                    <key>useAutomaticInputType</key>
                    <integer>0</integer>
                    <key>workflowTypeIdentifier</key>
                    <string>com.apple.Automator.servicesMenu</string>
                </dict>
            </dict>
            </plist>
            """

            do {
                try infoPlistContent.write(to: infoPlistURL, atomically: true, encoding: .utf8)
                try documentWflowContent.write(to: wflowURL, atomically: true, encoding: .utf8)
                installedCount += 1
            } catch {
                continue
            }
        }

        // Refresh macOS Dynamic Services & Pasteboard Server (pbs)
        NSUpdateDynamicServices()
        Task.detached {
            let pbs = Process()
            pbs.executableURL = URL(fileURLWithPath: "/System/Library/CoreServices/pbs")
            pbs.arguments = ["-update"]
            try? pbs.run()
            pbs.waitUntilExit()

            let lsreg = Process()
            lsreg.executableURL = URL(fileURLWithPath: "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister")
            lsreg.arguments = ["-f", Bundle.main.bundlePath]
            try? lsreg.run()
            lsreg.waitUntilExit()
        }

        isFinderContextMenuInstalled = (installedCount > 0)
        finderContextMenuStatus = "✅ \(installedCount) adet Native Sağ Tık Eylemi `~/Library/Services` ve `NSServices` içine kuruldu! (Finder -> Sağ Tık -> Hızlı Eylemler)"
    }

    public func revealServicesFolderInFinder() {
        let servicesDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Services")
        NSWorkspace.shared.open(servicesDir)
    }
}

// MARK: - 11. Native macOS NSServices & Custom URL Scheme Provider (Handles Finder Right-Click Menu Invocations!)
@MainActor
public final class FinderContextMenuServiceProvider: NSObject {
    public static let shared = FinderContextMenuServiceProvider()

    private func extractFilePath(from pboard: NSPasteboard) -> String? {
        if let urls = pboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let first = urls.first(where: { $0.isFileURL }) {
            return first.path
        }
        if let filenames = pboard.propertyList(forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String],
           let first = filenames.first {
            return first
        }
        return nil
    }

    // 1. 🍐 SuperMacHub — Nashi 360° Çarkında Aç
    @objc public func openInNashiWheelService(
        _ pboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        if let path = extractFilePath(from: pboard) {
            NashiToolkitManager.shared.selectedFilePath = path
            NashiToolkitManager.shared.showRadialWheelAtCursor()
        }
    }

    // 2. ✨ SuperMacHub — Arka Planı Sil (Vision AI)
    @objc public func removeBackgroundService(
        _ pboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        if let path = extractFilePath(from: pboard) {
            NashiToolkitManager.shared.selectedFilePath = path
            NashiToolkitManager.shared.removeBackgroundFromSelectedImage()
        }
    }

    // 3. 🖼️ SuperMacHub — Kayıpsız PNG'ye Dönüştür
    @objc public func convertToPNGService(
        _ pboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        if let path = extractFilePath(from: pboard) {
            NashiToolkitManager.shared.selectedFilePath = path
            NashiToolkitManager.shared.targetFormat = "PNG"
            NashiToolkitManager.shared.convertSelectedFile()
        }
    }

    // 4. 📄 SuperMacHub — Anında PDF'e Dönüştür
    @objc public func convertToPDFService(
        _ pboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        if let path = extractFilePath(from: pboard) {
            NashiToolkitManager.shared.selectedFilePath = path
            NashiToolkitManager.shared.targetFormat = "PDF"
            NashiToolkitManager.shared.convertSelectedFile()
        }
    }

    // 5. 🏝️ SuperMacHub — Dinamik Ada Dosya Rafına Gönder
    @objc public func sendToDynamicIslandService(
        _ pboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        if let path = extractFilePath(from: pboard) {
            NashiToolkitManager.shared.selectedFilePath = path
            NashiToolkitManager.shared.sendSelectedFileToDynamicIslandShelf()
        }
    }

    // 6. 🤖 SuperMacHub — Eney AI Spotlight ile Analiz Et
    @objc public func analyzeWithEneyService(
        _ pboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        if let path = extractFilePath(from: pboard) {
            NashiToolkitManager.shared.selectedFilePath = path
            EneyAIAgentManager.shared.showSpotlightOverlay()
            NashiToolkitManager.shared.sendSelectedFileToEneyAI()
        }
    }

    // URL Scheme Handler: supermachub://action?type=nashi_wheel&path=/Users/...
    @objc public func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }
        let queryItems = components.queryItems ?? []
        let actionType = queryItems.first(where: { $0.name == "type" })?.value ?? ""
        let filePath = queryItems.first(where: { $0.name == "path" })?.value ?? ""

        if !filePath.isEmpty {
            NashiToolkitManager.shared.selectedFilePath = filePath
        }

        switch actionType {
        case "nashi_wheel":
            NashiToolkitManager.shared.showRadialWheelAtCursor()
        case "remove_bg":
            NashiToolkitManager.shared.removeBackgroundFromSelectedImage()
        case "convert_png":
            NashiToolkitManager.shared.targetFormat = "PNG"
            NashiToolkitManager.shared.convertSelectedFile()
        case "convert_pdf":
            NashiToolkitManager.shared.targetFormat = "PDF"
            NashiToolkitManager.shared.convertSelectedFile()
        case "send_to_notch":
            NashiToolkitManager.shared.sendSelectedFileToDynamicIslandShelf()
        case "eney_analyze":
            EneyAIAgentManager.shared.showSpotlightOverlay()
            NashiToolkitManager.shared.sendSelectedFileToEneyAI()
        default:
            break
        }
    }
}

// MARK: - 12. Visual Replica & Installer Card for Native macOS Finder Right-Click Menu
public struct NativeFinderContextMenuStudioCard: View {
    @ObservedObject var nashi: NashiToolkitManager

    public var body: some View {
        HStack(alignment: .top, spacing: 22) {
            HStack(alignment: .bottom, spacing: 6) {
                mainMenuColumn
                submenuColumn
            }
            installerColumn
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.cyan.opacity(0.35), lineWidth: 1)
                )
        )
    }

    private var mainMenuColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            FinderMenuRow(icon: "arrow.up.right.square", title: "Aç")
            FinderMenuRow(icon: "chevron.right", title: "Şununla Aç", isRightArrow: true)
            Divider()
            FinderMenuRow(icon: "trash", title: "Çöp Sepeti'ne Taşı")
            Divider()
            FinderMenuRow(icon: "info.circle", title: "Bilgi Ver")
            FinderMenuRow(icon: "pencil", title: "Adını Değiştir")
            FinderMenuRow(icon: "doc.zipper", title: "Sıkıştır: \"\(nashi.activeFileDisplayName)\"")
            FinderMenuRow(icon: "plus.square.on.square", title: "Çoğalt")
            FinderMenuRow(icon: "eye", title: "Göz At")
            Divider()
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                Text("Hızlı Eylemler (SuperMacHub)")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.blue)
            )
            FinderMenuRow(icon: "photo", title: "Masaüstü Resmi Yap")
        }
        .padding(8)
        .frame(width: 230)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.12, green: 0.13, blue: 0.18).opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 12)
    }

    private var submenuColumn: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("macOS Native Sağ Tık Eylemleri")
                .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                .foregroundStyle(.cyan)
                .padding(.horizontal, 8)
                .padding(.top, 4)

            FinderSubmenuActionButton(title: "🍐 Nashi 360° Çarkında Aç") {
                nashi.showRadialWheelAtCursor()
            }
            FinderSubmenuActionButton(title: "✨ Arka Planı Sil (Vision AI)") {
                nashi.removeBackgroundFromSelectedImage()
            }
            FinderSubmenuActionButton(title: "🖼️ Kayıpsız PNG'ye Dönüştür") {
                nashi.targetFormat = "PNG"
                nashi.convertSelectedFile()
            }
            FinderSubmenuActionButton(title: "📄 Anında PDF'e Dönüştür") {
                nashi.targetFormat = "PDF"
                nashi.convertSelectedFile()
            }
            FinderSubmenuActionButton(title: "🏝️ Dinamik Ada Rafına Gönder") {
                nashi.sendSelectedFileToDynamicIslandShelf()
            }
            FinderSubmenuActionButton(title: "🤖 Eney AI ile Analiz Et") {
                EneyAIAgentManager.shared.showSpotlightOverlay()
                nashi.sendSelectedFileToEneyAI()
            }
        }
        .padding(8)
        .frame(width: 245)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.09, green: 0.11, blue: 0.16).opacity(0.98))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.cyan.opacity(0.55), lineWidth: 1.2)
                )
        )
        .shadow(color: .black.opacity(0.6), radius: 14)
    }

    private var installerColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🖱️ macOS Native Sağ Tık Menüsü & Hızlı Eylemler Entegrasyonu")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                Spacer()
                Text(nashi.isFinderContextMenuInstalled ? "✅ Sistem Menüsünde Aktif" : "⚠️ Kurulmadı")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(nashi.isFinderContextMenuInstalled ? Color.green.opacity(0.22) : Color.orange.opacity(0.22))
                    .foregroundStyle(nashi.isFinderContextMenuInstalled ? .green : .orange)
                    .clipShape(Capsule())
            }

            Text("Attığınız fotoğraftaki macOS Finder sağ tık menüsünün içindeki 'Hızlı Eylemler >' (Quick Actions) ve 'Servisler' kısmına 6 adet gerçek yerel (native) SuperMacHub işlemi ekler:")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(nashi.finderContextMenuStatus)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.cyan)

            HStack(spacing: 10) {
                Button("⚡ Sağ Tık Menüsüne Şimdi Kur / Güncelle") {
                    nashi.installNativeFinderRightClickQuickActions()
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)

                Button("📂 ~/Library/Services Klasörünü Aç") {
                    nashi.revealServicesFolderInFinder()
                }
                .buttonStyle(.bordered)
            }

            Text("💡 Not: Normal sağ tık yaptığınızda fotoğraftaki 'Hızlı Eylemler >' menüsünden bu 6 işlemi kullanabilirsiniz; ⇧ Shift + Sağ Tık yaptığınızda ise sistem menüsü yerine doğrudan 360° Nashi Çarkı açılır!")
                .font(.caption2)
                .foregroundStyle(.orange)
        }
    }
}

private struct FinderMenuRow: View {
    let icon: String
    let title: String
    var isRightArrow: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10.5))
                .foregroundStyle(.white.opacity(0.75))
                .frame(width: 14)
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.88))
                .lineLimit(1)
            Spacer()
            if isRightArrow {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
    }
}

private struct FinderSubmenuActionButton: View {
    let title: String
    let action: () -> Void
    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(isHovered ? .white : .cyan)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovered ? Color.blue : Color.white.opacity(0.04))
            )
            .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

private extension URL {
    func appendingPathNameSuffix(_ suffix: String) -> URL {
        let dir = deletingLastPathComponent()
        let name = lastPathComponent
        return dir.appendingPathComponent(name + suffix)
    }
}
