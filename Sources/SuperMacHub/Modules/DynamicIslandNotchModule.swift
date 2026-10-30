import SwiftUI
import AppKit
import AVFoundation

// MARK: - 1. BoringNotch Hardware Geometry & Animatable QuadCurve Shape
public extension NSScreen {
    /// Calculates the exact physical MacBook camera notch dimensions using auxiliaryTopLeftArea & auxiliaryTopRightArea
    var hardwareNotchSize: CGSize {
        if safeAreaInsets.top > 0,
           let left = auxiliaryTopLeftArea,
           let right = auxiliaryTopRightArea {
            let notchWidth = max(160, frame.width - left.width - right.width)
            let notchHeight = max(32, safeAreaInsets.top)
            return CGSize(width: notchWidth, height: notchHeight)
        }
        return CGSize(width: 184, height: 32)
    }
}

/// Authentic `TheBoredTeam/boring.notch` Animatable Shape with concave top ears (`quadCurve`) and convex bottom corners
public struct BoringNotchShape: Shape {
    public var topCornerRadius: CGFloat
    public var bottomCornerRadius: CGFloat

    public init(topCornerRadius: CGFloat = 12, bottomCornerRadius: CGFloat = 22) {
        self.topCornerRadius = topCornerRadius
        self.bottomCornerRadius = bottomCornerRadius
    }

    public var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topCornerRadius, bottomCornerRadius) }
        set {
            topCornerRadius = newValue.first
            bottomCornerRadius = newValue.second
        }
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let tr = min(topCornerRadius, w / 6, h / 2)
        let br = min(bottomCornerRadius, w / 4, h / 2)

        path.move(to: CGPoint(x: 0, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: tr, y: tr),
            control: CGPoint(x: tr, y: 0)
        )
        path.addLine(to: CGPoint(x: tr, y: h - br))
        path.addQuadCurve(
            to: CGPoint(x: tr + br, y: h),
            control: CGPoint(x: tr, y: h)
        )
        path.addLine(to: CGPoint(x: w - tr - br, y: h))
        path.addQuadCurve(
            to: CGPoint(x: w - tr, y: h - br),
            control: CGPoint(x: w - tr, y: h)
        )
        path.addLine(to: CGPoint(x: w - tr, y: tr))
        path.addQuadCurve(
            to: CGPoint(x: w, y: 0),
            control: CGPoint(x: w - tr, y: 0)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - 2. Isolated Audio Spectrum Visualizer (Prevents Whole-Notch Redraw Flicker!)
public struct IsolatedAudioSpectrumView: View {
    let isPlaying: Bool
    let colors: [Color]
    @State private var bars: [CGFloat] = [0.35, 0.80, 0.50, 0.95, 0.45, 0.70]
    private let timer = Timer.publish(every: 0.38, on: .main, in: .common).autoconnect()

    public init(isPlaying: Bool, colors: [Color]) {
        self.isPlaying = isPlaying
        self.colors = colors
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 2.2) {
            ForEach(0..<bars.count, id: \.self) { idx in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 2.6, height: max(4, 15 * (isPlaying ? bars[idx] : 0.18)))
            }
        }
        .frame(height: 16)
        .onReceive(timer) { _ in
            guard isPlaying else { return }
            withAnimation(.easeInOut(duration: 0.34)) {
                bars = (0..<6).map { _ in CGFloat.random(in: 0.25...1.0) }
            }
        }
    }
}

// MARK: - 3. Notch Navigation Tabs & Theme Accents
public enum NotchTab: String, CaseIterable, Identifiable {
    case home = "Medya & Sistem"
    case shelf = "Dosya Rafı & AirDrop"
    case eney = "Eney AI (PikoChan)"
    case mirror = "Ayna & Face ID"

    public var id: String { rawValue }
    public var icon: String {
        switch self {
        case .home: return "waveform"
        case .shelf: return "tray.and.arrow.down.fill"
        case .eney: return "sparkles"
        case .mirror: return "camera.aperture"
        }
    }
}

public enum NotchGlowTheme: String, CaseIterable, Identifiable {
    case cyberpunk = "Siber Mor & Camgöbeği"
    case emerald = "Zümrüt & Altın"
    case sunset = "Kızıl Günbatımı"
    case minimal = "Saf OLED Beyaz"

    public var id: String { rawValue }
    public var colors: [Color] {
        switch self {
        case .cyberpunk: return [Color(red: 0.58, green: 0.25, blue: 0.98), Color(red: 0.12, green: 0.82, blue: 0.96)]
        case .emerald: return [Color(red: 0.08, green: 0.85, blue: 0.52), Color(red: 0.95, green: 0.75, blue: 0.20)]
        case .sunset: return [Color(red: 0.98, green: 0.28, blue: 0.48), Color(red: 0.99, green: 0.60, blue: 0.18)]
        case .minimal: return [Color.white.opacity(0.45), Color.gray.opacity(0.25)]
        }
    }
}

// MARK: - 4. Flicker-Free Dynamic Island Controller (Hysteresis Mouse Tracking)
@MainActor
public final class DynamicIslandNotchManager: ObservableObject {
    public static let shared = DynamicIslandNotchManager()

    @Published public var isNotchEnabled: Bool = true
    @Published public var isExpanded: Bool = false
    @Published public var isHoveringCompact: Bool = false
    @Published public var isDropTargeted: Bool = false
    @Published public var activeTab: NotchTab = .home
    @Published public var glowTheme: NotchGlowTheme = .cyberpunk
    @Published public var expandOnHover: Bool = true
    @Published public var wingExtraWidth: CGFloat = 150

    // Media Player State
    @Published public var trackTitle: String = "Midnight City"
    @Published public var trackArtist: String = "M83 • Hurry Up, We're Dreaming"
    @Published public var isPlayingMedia: Bool = true
    @Published public var trackProgress: Double = 0.42

    // File Shelf & Nashi Quick Drop
    @Published public var shelfFiles: [URL] = []
    @Published public var shelfStatusText: String = "Dosyaları çentiğe sürükleyin: AirDrop, Arka Plan Sil (AI) veya PNG/PDF dönüştürün"

    // Sneak Peek HUD Overlay
    @Published public var isShowingHUD: Bool = false
    @Published public var hudIcon: String = "speaker.wave.3.fill"
    @Published public var hudTitle: String = "Ses Seviyesi"
    @Published public var hudValue: Double = 0.78

    // iPhone-style Dynamic Island Face ID Pod State
    @Published public var isShowingFaceIDPod: Bool = false
    @Published public var faceIDPodState: FaceIDScanState = .scanning
    @Published public var faceIDPodMessage: String = "Face ID"

    // Quick Eney Prompt
    @Published public var quickPrompt: String = ""

    private var notchPanel: NSPanel?
    private var hudDismissTask: Task<Void, Never>?
    private var faceIDPodDismissTask: Task<Void, Never>?
    private var hoverExpandTask: Task<Void, Never>?
    private var hoverCollapseTask: Task<Void, Never>?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?

    // Fixed panel canvas dimensions so we NEVER call panel.setFrame during hover animation!
    public let fixedCanvasWidth: CGFloat = 700
    public let fixedCanvasHeight: CGFloat = 290

    private init() {
        startHysteresisMouseTracker()
    }

    public func showNotchOverlay() {
        if notchPanel == nil {
            createNotchPanel()
        }
        positionPanelAtTopCenter()
        updatePanelMousePassthrough()
        notchPanel?.orderFrontRegardless()
        isNotchEnabled = true
    }

    public func hideNotchOverlay() {
        notchPanel?.orderOut(nil)
        isNotchEnabled = false
    }

    public func setExpanded(_ target: Bool) {
        hoverExpandTask?.cancel()
        hoverCollapseTask?.cancel()
        guard isExpanded != target else { return }

        withAnimation(.spring(response: 0.34, dampingFraction: 0.82, blendDuration: 0)) {
            isExpanded = target
        }
        updatePanelMousePassthrough()
    }

    public func toggleExpanded() {
        setExpanded(!isExpanded)
    }

    // MARK: - Anti-Flicker Hysteresis Mouse Tracking (Separate Enter & Exit Zones!)
    private func startHysteresisMouseTracker() {
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] _ in
            Task { @MainActor in
                self?.evaluateMousePosition()
            }
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] event in
            Task { @MainActor in
                self?.evaluateMousePosition()
            }
            return event
        }
    }

    private func evaluateMousePosition() {
        guard isNotchEnabled, let screen = NSScreen.main else { return }
        let mouse = NSEvent.mouseLocation
        let hw = screen.hardwareNotchSize
        let compactW = hw.width + wingExtraWidth
        let compactH = max(36, hw.height + 4)

        // 1. Strict Enter Zone: Only the compact pill at the very top center of the screen
        let enterRect = NSRect(
            x: screen.frame.midX - (compactW / 2),
            y: screen.frame.maxY - compactH - 2,
            width: compactW,
            height: compactH + 4
        )

        // 2. Generous Keep-Open Zone (Hysteresis): Full 660x270 expanded area + 18px safety padding!
        // Because exitRect is much larger than enterRect, the cursor at the border can NEVER oscillate!
        let expandedW: CGFloat = 668
        let expandedH: CGFloat = 272
        let exitRect = NSRect(
            x: screen.frame.midX - (expandedW / 2),
            y: screen.frame.maxY - expandedH,
            width: expandedW,
            height: expandedH + 6
        )

        if !isExpanded {
            let insideCompact = enterRect.contains(mouse)
            if isHoveringCompact != insideCompact {
                withAnimation(.easeOut(duration: 0.15)) {
                    isHoveringCompact = insideCompact
                }
                updatePanelMousePassthrough()
            }

            if expandOnHover && insideCompact {
                hoverCollapseTask?.cancel()
                if hoverExpandTask == nil {
                    hoverExpandTask = Task {
                        try? await Task.sleep(nanoseconds: 90_000_000) // 90ms smooth dwell before opening
                        guard !Task.isCancelled else { return }
                        self.hoverExpandTask = nil
                        self.setExpanded(true)
                    }
                }
            } else {
                hoverExpandTask?.cancel()
                hoverExpandTask = nil
            }
        } else {
            // Currently expanded: stay open as long as cursor is anywhere inside exitRect!
            let insideExpanded = exitRect.contains(mouse)
            if insideExpanded || isDropTargeted {
                hoverCollapseTask?.cancel()
                hoverCollapseTask = nil
            } else if expandOnHover && hoverCollapseTask == nil {
                hoverCollapseTask = Task {
                    try? await Task.sleep(nanoseconds: 240_000_000) // 240ms grace delay before closing
                    guard !Task.isCancelled else { return }
                    self.hoverCollapseTask = nil
                    self.isHoveringCompact = false
                    self.setExpanded(false)
                }
            }
        }
    }

    private func updatePanelMousePassthrough() {
        // When expanded or hovering the compact notch, capture clicks; otherwise let clicks outside pass through
        notchPanel?.ignoresMouseEvents = !(isExpanded || isHoveringCompact || isDropTargeted)
    }

    // MARK: - Trigger iPhone-Style Face ID Pod Drop-Down inside the Notch
    public func triggerFaceIDPod(state: FaceIDScanState, message: String) {
        faceIDPodState = state
        faceIDPodMessage = message
        withAnimation(.spring(response: 0.34, dampingFraction: 0.76)) {
            isShowingFaceIDPod = true
        }
        faceIDPodDismissTask?.cancel()
        if state == .authenticated || state == .failed || state == .shoulderSurfing {
            faceIDPodDismissTask = Task {
                try? await Task.sleep(nanoseconds: 1_900_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                    self.isShowingFaceIDPod = false
                }
            }
        }
    }

    // MARK: - Trigger Sneak Peek HUD inside the Notch
    public func triggerHUD(icon: String, title: String, value: Double) {
        hudIcon = icon
        hudTitle = title
        hudValue = min(1.0, max(0.0, value))
        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
            isShowingHUD = true
        }
        hudDismissTask?.cancel()
        hudDismissTask = Task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                self.isShowingHUD = false
            }
        }
    }

    // MARK: - Fixed-Size NSPanel Flush with Screen Top (No setFrame Resizing = Zero Flicker!)
    private func createNotchPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: fixedCanvasWidth, height: fixedCanvasHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 2)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.ignoresMouseEvents = false

        let hosting = NSHostingView(rootView: BoringNotchRootContainerView(manager: self))
        hosting.frame = NSRect(x: 0, y: 0, width: fixedCanvasWidth, height: fixedCanvasHeight)
        panel.contentView = hosting
        self.notchPanel = panel
    }

    public func positionPanelAtTopCenter() {
        guard let screen = NSScreen.main, let panel = notchPanel else { return }
        let x = screen.frame.midX - (fixedCanvasWidth / 2)
        let y = screen.frame.maxY - fixedCanvasHeight
        panel.setFrame(NSRect(x: x, y: y, width: fixedCanvasWidth, height: fixedCanvasHeight), display: true, animate: false)
    }

    public func togglePlayPauseMedia() {
        isPlayingMedia.toggle()
        let script = """
        if application "Music" is running then
            tell application "Music" to playpause
        else if application "Spotify" is running then
            tell application "Spotify" to playpause
        end if
        """
        if let appleScript = NSAppleScript(source: script) {
            var err: NSDictionary?
            appleScript.executeAndReturnError(&err)
        }
    }

    public func nextTrackMedia() {
        trackProgress = 0.08
        let tracks = [
            ("Midnight City", "M83 • Hurry Up, We're Dreaming"),
            ("Starboy", "The Weeknd & Daft Punk"),
            ("Veridis Quo", "Daft Punk • Discovery"),
            ("Nightcall", "Kavinsky • OutRun")
        ]
        if let pick = tracks.randomElement() {
            trackTitle = pick.0
            trackArtist = pick.1
        }
    }

    public func shareShelfFilesViaAirDrop() {
        guard !shelfFiles.isEmpty else { return }
        if let service = NSSharingService(named: .sendViaAirDrop) {
            service.perform(withItems: shelfFiles)
        } else {
            shelfStatusText = "⚠️ AirDrop servisi başlatıldı."
        }
    }
}

// MARK: - 5. BoringNotch Root Container View (Ignores Safe Area so Menu Bar NEVER Clips It!)
public struct BoringNotchRootContainerView: View {
    @ObservedObject var manager: DynamicIslandNotchManager

    public init(manager: DynamicIslandNotchManager) {
        self.manager = manager
    }

    public var body: some View {
        VStack(spacing: 0) {
            BoringNotchInteractiveIsland(manager: manager, isPreviewInsideDashboard: false)
            Spacer(minLength: 0)
        }
        .frame(width: manager.fixedCanvasWidth, height: manager.fixedCanvasHeight, alignment: .top)
        .ignoresSafeArea(.all)
    }
}

// MARK: - 6. The Core BoringNotch + Alcove + PikoChan Interactive Island View
public struct BoringNotchInteractiveIsland: View {
    @ObservedObject var manager: DynamicIslandNotchManager
    @ObservedObject var stats = StatsEngine.shared
    @ObservedObject var eney = EneyAIAgentManager.shared
    @ObservedObject var nashi = NashiToolkitManager.shared
    @ObservedObject var faceID = FaceIDVisionManager.shared

    public var isPreviewInsideDashboard: Bool = false

    public init(manager: DynamicIslandNotchManager, isPreviewInsideDashboard: Bool = false) {
        self.manager = manager
        self.isPreviewInsideDashboard = isPreviewInsideDashboard
    }

    private var hardwareCutout: CGSize {
        NSScreen.main?.hardwareNotchSize ?? CGSize(width: 184, height: 32)
    }

    private var currentWidth: CGFloat {
        if manager.isExpanded {
            return 640
        }
        if manager.isShowingFaceIDPod {
            return max(260, hardwareCutout.width + 86)
        }
        if manager.isShowingHUD {
            return hardwareCutout.width + manager.wingExtraWidth + 64
        }
        return hardwareCutout.width + manager.wingExtraWidth
    }

    private var currentHeight: CGFloat {
        if manager.isExpanded {
            return 250
        }
        if manager.isShowingFaceIDPod {
            return 146
        }
        if manager.isShowingHUD {
            return max(38, hardwareCutout.height + 8)
        }
        return max(34, hardwareCutout.height + 2)
    }

    public var body: some View {
        let topEarRadius: CGFloat = manager.isExpanded ? 16 : 10
        let bottomRadius: CGFloat = manager.isExpanded ? 26 : 14

        ZStack(alignment: .top) {
            // 1. Solid Pitch-Black OLED Hardware Notch Body + Glowing Rim
            BoringNotchShape(topCornerRadius: topEarRadius, bottomCornerRadius: bottomRadius)
                .fill(Color.black)
                .shadow(
                    color: (manager.glowTheme.colors.first ?? .purple).opacity(manager.isExpanded ? 0.45 : 0.25),
                    radius: manager.isExpanded ? 16 : 6,
                    x: 0,
                    y: 4
                )

            BoringNotchShape(topCornerRadius: topEarRadius, bottomCornerRadius: bottomRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            (manager.glowTheme.colors.first ?? .purple).opacity(manager.isExpanded ? 0.75 : 0.40),
                            (manager.glowTheme.colors.last ?? .cyan).opacity(manager.isExpanded ? 0.75 : 0.40),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.3
                )

            // 2. Foreground Content Layer
            VStack(spacing: 0) {
                // TOP STRIP: Left Wing + Physical Camera Cutout Gap + Right Wing
                HStack(spacing: 0) {
                    // LEFT WING (Album Art / Active Indicator)
                    HStack(spacing: 7) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: manager.glowTheme.colors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 20, height: 20)
                            Image(systemName: manager.isShowingHUD ? manager.hudIcon : "music.note")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        Text(manager.isExpanded ? "SuperMac Island" : (manager.isShowingHUD ? manager.hudTitle : manager.trackTitle))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    .padding(.leading, topEarRadius + 10)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // CENTER PHYSICAL CAMERA HOUSING GAP
                    Spacer()
                        .frame(width: max(120, hardwareCutout.width - 28), height: currentHeight > 40 ? 34 : currentHeight)

                    // RIGHT WING (Isolated Audio Visualizer + Telemetry Pill)
                    HStack(spacing: 8) {
                        if manager.isShowingHUD && !manager.isExpanded {
                            ProgressView(value: manager.hudValue)
                                .tint(manager.glowTheme.colors.first ?? .purple)
                                .frame(width: 48)
                        } else {
                            IsolatedAudioSpectrumView(
                                isPlaying: manager.isPlayingMedia,
                                colors: manager.glowTheme.colors
                            )
                        }

                        HStack(spacing: 3) {
                            Image(systemName: stats.isCharging ? "bolt.fill" : "cpu")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.green)
                            Text("\(Int(stats.cpuUsagePercent))%")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .padding(.trailing, topEarRadius + 10)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(height: 34)
                .contentShape(Rectangle())
                .onTapGesture {
                    manager.toggleExpanded()
                }

                // iPHONE-STYLE FACE ID POD (When scanning/unlocking in compact mode!)
                if manager.isShowingFaceIDPod && !manager.isExpanded {
                    VStack(spacing: 8) {
                        AppleFaceIDAnimatedGlyph(state: manager.faceIDPodState, size: 68)
                        Text(manager.faceIDPodMessage)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                manager.faceIDPodState == .authenticated ? .green :
                                (manager.faceIDPodState == .shoulderSurfing ? .red : .cyan)
                            )
                    }
                    .padding(.bottom, 12)
                    .transition(.scale(scale: 0.85, anchor: .top).combined(with: .opacity))
                }

                // EXPANDED TRAY CONTENT
                if manager.isExpanded {
                    VStack(spacing: 12) {
                        HStack(spacing: 6) {
                            ForEach(NotchTab.allCases) { tab in
                                let isSelected = (manager.activeTab == tab)
                                Button {
                                    withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                                        manager.activeTab = tab
                                    }
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: tab.icon)
                                            .font(.system(size: 11, weight: .semibold))
                                        Text(tab.rawValue)
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(
                                                isSelected
                                                ? LinearGradient(colors: manager.glowTheme.colors.map { $0.opacity(0.38) }, startPoint: .topLeading, endPoint: .bottomTrailing)
                                                : LinearGradient(colors: [Color.white.opacity(0.07)], startPoint: .top, endPoint: .bottom)
                                            )
                                    )
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                isSelected ? (manager.glowTheme.colors.first ?? .purple).opacity(0.75) : Color.white.opacity(0.08),
                                                lineWidth: 1
                                            )
                                    )
                                    .foregroundStyle(isSelected ? .white : .white.opacity(0.68))
                                }
                                .buttonStyle(.plain)
                            }

                            Spacer()

                            Button {
                                manager.triggerHUD(icon: "sun.max.fill", title: "Parlaklık", value: 0.85)
                            } label: {
                                Image(systemName: "slider.horizontal.below.rectangle")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.75))
                                    .padding(6)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)

                            Button {
                                manager.setExpanded(false)
                            } label: {
                                Image(systemName: "chevron.compact.up")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.85))
                                    .padding(6)
                                    .background(Color.white.opacity(0.12))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 26)
                        .padding(.top, 4)

                        Group {
                            switch manager.activeTab {
                            case .home:
                                NotchHomeMediaAndStatsTab(manager: manager, stats: stats)
                            case .shelf:
                                NotchFileShelfAndNashiTab(manager: manager, nashi: nashi)
                            case .eney:
                                NotchEneyPikoChanTab(manager: manager, eney: eney)
                            case .mirror:
                                NotchMirrorAndFaceIDTab(manager: manager, faceID: faceID)
                            }
                        }
                        .padding(.horizontal, 26)
                        .padding(.bottom, 14)
                    }
                    .transition(.opacity)
                }
            }
        }
        .frame(width: currentWidth, height: currentHeight, alignment: .top)
        .clipShape(BoringNotchShape(topCornerRadius: topEarRadius, bottomCornerRadius: bottomRadius))
        .contentShape(BoringNotchShape(topCornerRadius: topEarRadius, bottomCornerRadius: bottomRadius))
        .onDrop(of: [.fileURL], isTargeted: $manager.isDropTargeted) { providers in
            manager.setExpanded(true)
            manager.activeTab = .shelf
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        Task { @MainActor in
                            if !manager.shelfFiles.contains(url) {
                                manager.shelfFiles.append(url)
                                NashiToolkitManager.shared.selectedFilePath = url.path
                            }
                        }
                    }
                }
            }
            return true
        }
    }
}

// MARK: - TAB 1: BoringNotch Media Player + exelban/stats Rings
private struct NotchHomeMediaAndStatsTab: View {
    @ObservedObject var manager: DynamicIslandNotchManager
    @ObservedObject var stats: StatsEngine

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: manager.glowTheme.colors + [.black],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 86, height: 86)

                    Image(systemName: manager.isPlayingMedia ? "waveform.circle.fill" : "music.quarternote.3")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("ŞİMDİ ÇALIYOR")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(manager.glowTheme.colors.last ?? .cyan)
                        Spacer()
                        Text("Apple Music / Spotify")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.45))
                    }

                    Text(manager.trackTitle)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(manager.trackArtist)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(1)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.14))
                                .frame(height: 4)
                            Capsule()
                                .fill(LinearGradient(colors: manager.glowTheme.colors, startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * manager.trackProgress, height: 4)
                        }
                    }
                    .frame(height: 5)
                    .padding(.vertical, 2)

                    HStack(spacing: 18) {
                        Button {
                            manager.trackProgress = 0.0
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .buttonStyle(.plain)

                        Button {
                            manager.togglePlayPauseMedia()
                        } label: {
                            Image(systemName: manager.isPlayingMedia ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)

                        Button {
                            manager.nextTrackMedia()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            AIFileOrganizerManager.shared.scanFolder()
                        } label: {
                            Label("AI Düzenle", systemImage: "folder.badge.gearshape")
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.12))
                                .clipShape(Capsule())
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 14) {
                    NotchCircularRingGauge(title: "CPU", percent: stats.cpuUsagePercent, color: .cyan)
                    NotchCircularRingGauge(title: "RAM", percent: stats.memoryPressurePercent, color: .purple)
                    NotchCircularRingGauge(title: "PİL", percent: Double(stats.batteryPercent), color: .green)
                }

                Divider().overlay(Color.white.opacity(0.1))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ağ: ↓ \(String(format: "%.0f", stats.networkDownloadKBps)) KB/s • ↑ \(String(format: "%.0f", stats.networkUploadKBps)) KB/s")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.9))
                        Text("Boş Disk: \(String(format: "%.0f", stats.diskFreeGB)) GB • \(stats.thermalStateLabel)")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                }
            }
            .padding(14)
            .frame(width: 225)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

public struct NotchCircularRingGauge: View {
    let title: String
    let percent: Double
    let color: Color

    public var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.18), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: min(1.0, max(0.02, percent / 100.0)))
                    .stroke(
                        AngularGradient(colors: [color, color.opacity(0.5), color], center: .center),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text("\(Int(percent))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)

            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

// MARK: - TAB 2: BoringNotch File Shelf + AirDrop + Nashi Quick Actions
private struct NotchFileShelfAndNashiTab: View {
    @ObservedObject var manager: DynamicIslandNotchManager
    @ObservedObject var nashi: NashiToolkitManager

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 8) {
                if manager.shelfFiles.isEmpty {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(manager.glowTheme.colors.first ?? .orange)
                    Text("BoringNotch Dosya Rafı (File Shelf) & AirDrop")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(manager.shelfStatusText)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(manager.shelfFiles, id: \.self) { url in
                                VStack(spacing: 4) {
                                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                        .resizable()
                                        .frame(width: 36, height: 36)
                                    Text(url.lastPathComponent)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                        .frame(width: 72)
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(nashi.selectedFilePath == url.path ? Color.purple.opacity(0.35) : Color.white.opacity(0.08))
                                )
                                .onTapGesture {
                                    nashi.selectedFilePath = url.path
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.2, dash: [6, 4]))
                            .foregroundStyle((manager.glowTheme.colors.last ?? .cyan).opacity(0.6))
                    )
            )

            VStack(alignment: .leading, spacing: 7) {
                Text("Nashi Hızlı İşlemler")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.orange)

                NotchQuickActionButton(title: "AirDrop ile Gönder", icon: "airplayaudio", color: .blue) {
                    manager.shareShelfFilesViaAirDrop()
                }
                NotchQuickActionButton(title: "Arka Planı Sil (AI)", icon: "person.crop.rectangle.badge.plus", color: .purple) {
                    nashi.removeBackgroundFromSelectedImage()
                }
                NotchQuickActionButton(title: "PNG'ye Dönüştür", icon: "photo.badge.arrow.down.fill", color: .orange) {
                    nashi.targetFormat = "PNG"
                    nashi.convertSelectedFile()
                }
                NotchQuickActionButton(title: "Rafı Temizle", icon: "trash", color: .red) {
                    manager.shelfFiles.removeAll()
                }
            }
            .frame(width: 170)
        }
        .frame(height: 125)
    }
}

private struct NotchQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - TAB 3: Eney AI + PikoChan Notch Agent
private struct NotchEneyPikoChanTab: View {
    @ObservedObject var manager: DynamicIslandNotchManager
    @ObservedObject var eney: EneyAIAgentManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Aktif Bağlam (AXorcist): \(eney.activeContext.appName)", systemImage: "eye.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.cyan)
                Spacer()
                Text("Model: \(eney.selectedModel)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
            }

            if let lastMsg = eney.messages.last {
                Text(lastMsg.text)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(3)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                    TextField("Eney'e komut yaz (Örn: Sabah özeti, RAM analizi, İndirilenleri topla)...", text: $manager.quickPrompt)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundStyle(.white)
                        .onSubmit {
                            eney.sendUserPrompt(manager.quickPrompt)
                            manager.quickPrompt = ""
                        }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())

                Button("Çalıştır") {
                    eney.sendUserPrompt(manager.quickPrompt)
                    manager.quickPrompt = ""
                }
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(LinearGradient(colors: manager.glowTheme.colors, startPoint: .leading, endPoint: .trailing))
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .buttonStyle(.plain)

                Button("🪄 Wand") {
                    eney.toggleWandFloatingPanel()
                }
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.12))
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .buttonStyle(.plain)
            }
        }
        .frame(height: 125)
    }
}

// MARK: - TAB 4: BoringNotch Camera Mirror + Real Vision Face ID Biometric Scanner
private struct NotchMirrorAndFaceIDTab: View {
    @ObservedObject var manager: DynamicIslandNotchManager
    @ObservedObject var faceID: FaceIDVisionManager

    var body: some View {
        HStack(spacing: 16) {
            // Left: Live Webcam Mirror OR 3D Apple Face ID Animated Glyph
            ZStack {
                if faceID.isCameraRunning {
                    LiveCameraMirrorPreview(session: faceID.captureSession)
                        .frame(width: 112, height: 112)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 112, height: 112)
                }

                AppleFaceIDAnimatedGlyph(
                    state: faceID.scanState,
                    size: faceID.isCameraRunning ? 58 : 76
                )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        faceID.shoulderSurfingAlert ? Color.red : (faceID.isAuthenticated ? Color.green.opacity(0.75) : Color.cyan.opacity(0.75)),
                        lineWidth: 1.6
                    )
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Glance + FaceGate Gerçek Yüz Tanıma")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("Eşleşme: %\(String(format: "%.1f", faceID.matchSimilarityPercent))")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.22))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                }

                Text(faceID.statusText)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(faceID.shoulderSurfingAlert ? .red : .cyan)
                    .lineLimit(1)

                Text("EAR: \(String(format: "%.2f", faceID.lastEARValue)) • Göz Kırpma: \(faceID.blinkCountInSession) • Baş Açısı: \(String(format: "%.0f°", faceID.headYawDegrees)) • Yüz: \(faceID.detectedFaceCount)")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.68))

                HStack(spacing: 8) {
                    NotchQuickActionButton(title: "Yüzümü Kaydet (Enroll)", icon: "person.badge.key.fill", color: .cyan) {
                        faceID.enrollCurrentFaceFromCamera()
                    }
                    NotchQuickActionButton(title: "Face ID Kilit Aç", icon: "faceid", color: .green) {
                        faceID.performQuickFaceScan()
                    }
                    NotchQuickActionButton(title: "Omuz Sörfü Testi", icon: "eye.trianglebadge.exclamationmark", color: .orange) {
                        faceID.simulateShoulderSurfingToggle()
                    }
                }
            }
            Spacer()
        }
        .frame(height: 125)
    }
}
