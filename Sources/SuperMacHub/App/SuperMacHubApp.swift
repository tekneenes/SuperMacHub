import SwiftUI
import AppKit

public enum SidebarSection: String, CaseIterable, Identifiable {
    case notchStudio = "Dinamik Ada Stüdyosu (BoringNotch)"
    case bentoOverview = "Bento Kontrol Merkezi (21 Modül)"
    case eneyAI = "01. Eney AI & Wand (⌥+W)"
    case aiFileOrganizer = "02. AI Dosya Düzenleyici"
    case nashiToolkit = "03. Nashi File Toolkit"
    case statsMonitor = "04. Stats Sistem Monitörü"
    case mouseAndInput = "05. Mouse Fix & Window Loop"
    case utilitiesVault = "09-21. Pano, OCR, Pil & Araçlar"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .notchStudio: return "rectangle.topthird.inset.filled"
        case .bentoOverview: return "square.grid.3x3.topleft.filled"
        case .eneyAI: return "wand.and.stars"
        case .aiFileOrganizer: return "folder.fill.badge.gearshape"
        case .nashiToolkit: return "shippingbox.and.arrow.backward.fill"
        case .statsMonitor: return "chart.xyaxis.line"
        case .mouseAndInput: return "computermouse.fill"
        case .utilitiesVault: return "wrench.and.screwdriver.fill"
        }
    }
}

@MainActor
public final class HubDashboardState: ObservableObject {
    public static let shared = HubDashboardState()

    // Start directly on the new BoringNotch Dynamic Island Studio so the user immediately sees the upgraded design!
    @Published public var selectedSection: SidebarSection = .notchStudio
    @Published public var enabledModules: Set<ModuleID> = Set(ModuleID.allCases)
    @Published public var searchFilter: String = ""

    private init() {}

    public func isModuleEnabled(_ id: ModuleID) -> Bool {
        enabledModules.contains(id)
    }

    public func toggleModule(_ id: ModuleID) {
        if enabledModules.contains(id) {
            enabledModules.remove(id)
            if id == .dynamicIsland { DynamicIslandNotchManager.shared.hideNotchOverlay() }
            if id == .mouseFix { MouseFixManager.shared.stopMouseFix() }
        } else {
            enabledModules.insert(id)
            if id == .dynamicIsland { DynamicIslandNotchManager.shared.showNotchOverlay() }
            if id == .mouseFix { MouseFixManager.shared.startMouseFix() }
        }
    }
}

// MARK: - Liquid Glass Design System Modifiers & Components
public struct GlassCardModifier: ViewModifier {
    var accent: Color
    var cornerRadius: CGFloat = 20

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.075),
                                    Color.white.opacity(0.025)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [accent.opacity(0.14), Color.clear],
                                center: .topLeading,
                                startRadius: 5,
                                endRadius: 260
                            )
                        )
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    accent.opacity(0.55),
                                    Color.white.opacity(0.14),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.1
                        )
                }
            )
    }
}

public extension View {
    func liquidGlassCard(accent: Color = .purple, cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCardModifier(accent: accent, cornerRadius: cornerRadius))
    }
}

public struct SparklineAreaChart: View {
    let values: [Double]
    let color: Color

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let pts = values.isEmpty ? [10.0, 20.0] : values
            let stepX = w / CGFloat(max(1, pts.count - 1))

            ZStack {
                // Filled Gradient Area
                Path { path in
                    path.move(to: CGPoint(x: 0, y: h))
                    for (i, val) in pts.enumerated() {
                        let x = CGFloat(i) * stepX
                        let y = h - (CGFloat(min(100, max(0, val))) / 100.0) * h
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.42), color.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Top Stroke Line
                Path { path in
                    for (i, val) in pts.enumerated() {
                        let x = CGFloat(i) * stepX
                        let y = h - (CGFloat(min(100, max(0, val))) / 100.0) * h
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

public final class SuperMacAppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        Task { @MainActor in
            DynamicIslandNotchManager.shared.showNotchOverlay()
            for window in NSApplication.shared.windows where !(window is NSPanel) {
                window.makeKeyAndOrderFront(nil)
                window.center()
            }
        }
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        for window in sender.windows where !(window is NSPanel) {
            window.makeKeyAndOrderFront(nil)
        }
        return true
    }
}

@main
public struct SuperMacHubApp: App {
    @NSApplicationDelegateAdaptor(SuperMacAppDelegate.self) var appDelegate
    @StateObject private var hubState = HubDashboardState.shared
    @StateObject private var stats = StatsEngine.shared
    @StateObject private var notch = DynamicIslandNotchManager.shared
    @StateObject private var utils = SystemUtilitiesManager.shared

    public init() {}

    public var body: some Scene {
        WindowGroup("SuperMacHub — All-in-One AI & Sistem Merkezi") {
            MainHubWindowView()
                .frame(minWidth: 1180, minHeight: 780)
                .preferredColorScheme(.dark)
                .onAppear {
                    notch.showNotchOverlay()
                }
        }
        .windowStyle(.hiddenTitleBar)

        MenuBarExtra {
            StatsMenuBarPopupView()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.xaxis.ascending")
                Text("CPU \(Int(stats.cpuUsagePercent))% • RAM \(Int(stats.memoryPressurePercent))%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
            }
        }
        .menuBarExtraStyle(.window)
    }
}

public struct MainHubWindowView: View {
    @ObservedObject var hubState = HubDashboardState.shared
    @ObservedObject var stats = StatsEngine.shared
    @ObservedObject var notch = DynamicIslandNotchManager.shared
    @ObservedObject var utils = SystemUtilitiesManager.shared

    public var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // Custom Obsidian Glass Sidebar
                VStack(alignment: .leading, spacing: 14) {
                    // Brand Header
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: notch.glowTheme.colors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                                .shadow(color: (notch.glowTheme.colors.first ?? .purple).opacity(0.5), radius: 8)
                            Image(systemName: "sparkles.rectangle.stack.fill")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SuperMacHub")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                            Text("BoringNotch + Eney + Stats")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.cyan)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    Divider().overlay(Color.white.opacity(0.08)).padding(.horizontal, 14)

                    // Navigation Pills
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 6) {
                            ForEach(SidebarSection.allCases) { section in
                                let isSelected = (hubState.selectedSection == section)
                                Button {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                        hubState.selectedSection = section
                                    }
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: section.icon)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                                            .frame(width: 22)
                                        Text(section.rawValue)
                                            .font(.system(size: 12.5, weight: isSelected ? .bold : .medium, design: .rounded))
                                            .foregroundStyle(isSelected ? .white : .white.opacity(0.72))
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(
                                                isSelected
                                                ? LinearGradient(colors: notch.glowTheme.colors.map { $0.opacity(0.38) }, startPoint: .leading, endPoint: .trailing)
                                                : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(
                                                isSelected ? (notch.glowTheme.colors.first ?? .purple).opacity(0.6) : Color.clear,
                                                lineWidth: 1
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12)
                    }

                    Spacer()

                    // Live Hardware Mini Card at Bottom of Sidebar
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle().fill(.green).frame(width: 7, height: 7)
                            Text("Canlı Sistem Telemetrisi")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                            Spacer()
                            Text("\(hubState.enabledModules.count)/21")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(.cyan)
                        }
                        HStack(spacing: 12) {
                            NotchCircularRingGauge(title: "CPU", percent: stats.cpuUsagePercent, color: .cyan)
                            NotchCircularRingGauge(title: "RAM", percent: stats.memoryPressurePercent, color: .purple)
                            NotchCircularRingGauge(title: "PİL", percent: Double(stats.batteryPercent), color: .green)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(14)
                    .liquidGlassCard(accent: .cyan, cornerRadius: 16)
                    .padding(12)
                }
                .frame(width: 268)
                .background(Color(red: 0.04, green: 0.04, blue: 0.07))

                Divider().overlay(Color.white.opacity(0.08))

                // Main Content Area
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        switch hubState.selectedSection {
                        case .notchStudio:
                            BoringNotchStudioPanelView()
                        case .bentoOverview:
                            BentoOverviewPanel()
                        case .eneyAI:
                            EneyAIPanelView()
                        case .aiFileOrganizer:
                            AIFileOrganizerPanelView()
                        case .nashiToolkit:
                            NashiToolkitPanelView()
                        case .statsMonitor:
                            StatsMonitorPanelView()
                        case .mouseAndInput:
                            MouseAndWindowPanelView()
                        case .utilitiesVault:
                            UtilitiesVaultPanelView()
                        }
                    }
                    .padding(28)
                }
                .background(
                    ZStack {
                        Color(red: 0.05, green: 0.05, blue: 0.08)
                        RadialGradient(
                            colors: [(notch.glowTheme.colors.first ?? .purple).opacity(0.14), Color.clear],
                            center: .topTrailing,
                            startRadius: 20,
                            endRadius: 520
                        )
                    }
                )
            }

            // CleanShield Overlay
            if utils.isCleanShieldActive {
                VStack(spacing: 18) {
                    Image(systemName: "keyboard.badge.ellipsis")
                        .font(.system(size: 64))
                        .foregroundStyle(.red)
                    Text("Klavye & Ekran Temizlik Kilidi Aktif")
                        .font(.title.bold())
                    Text("\(utils.cleanShieldSecondsRemaining) saniye boyunca klavye ve dokunmatik yüzeyinizi güvenle silebilirsiniz.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Button("Kilidi Hemen Aç") {
                        utils.stopCleanShield()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.large)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.92))
            }
        }
    }
}

// MARK: - 0. NEW! BoringNotch Dynamic Island Studio & Live Interactive Stage
public struct BoringNotchStudioPanelView: View {
    @ObservedObject var notch = DynamicIslandNotchManager.shared
    @ObservedObject var dock = DockWidgetsManager.shared
    @ObservedObject var faceID = FaceIDVisionManager.shared

    public var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Dinamik Ada Stüdyosu")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                        Text("TheBoredTeam/boring.notch + Alcove + PikoChan Çekirdeği")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.25))
                            .foregroundStyle(.purple)
                            .clipShape(Capsule())
                    }
                    Text("Gerçek MacBook kamera çentiğine (`NSScreen.auxiliaryTopLeftArea`) sıfıra sıfır oturan içbükey `quadCurve` kulaklı OLED Dinamik Ada.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    notch.toggleExpanded()
                } label: {
                    Label(notch.isExpanded ? "Adayı Küçült (Compact)" : "Adayı Genişlet (Expanded)", systemImage: notch.isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(LinearGradient(colors: notch.glowTheme.colors, startPoint: .leading, endPoint: .trailing))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            // LIVE INTERACTIVE STAGE: Simulated MacBook Top Wallpaper + Real Interactive BoringNotch!
            VStack(spacing: 0) {
                // Simulated macOS Menu Bar Backdrop
                ZStack(alignment: .top) {
                    // Ambient Wallpaper Top Strip
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.14, green: 0.10, blue: 0.28),
                                    Color(red: 0.06, green: 0.14, blue: 0.24),
                                    Color(red: 0.04, green: 0.04, blue: 0.07)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            // Simulated macOS Top Menu Bar Strip
                            VStack {
                                HStack {
                                    HStack(spacing: 14) {
                                        Image(systemName: "apple.logo").font(.system(size: 12, weight: .bold))
                                        Text("SuperMacHub").font(.system(size: 12, weight: .bold))
                                        Text("Dosya").font(.system(size: 12))
                                        Text("Düzen").font(.system(size: 12))
                                        Text("Görünüm").font(.system(size: 12))
                                    }
                                    .foregroundStyle(.white.opacity(0.8))
                                    Spacer()
                                    HStack(spacing: 12) {
                                        Image(systemName: "wifi")
                                        Image(systemName: "magnifyingglass")
                                        Image(systemName: "switch.2")
                                        Text("Sal 21:48")
                                    }
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.8))
                                }
                                .padding(.horizontal, 20)
                                .frame(height: 32)
                                .background(Color.black.opacity(0.28))
                                Spacer()
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                        )

                    // The Real Interactive BoringNotch Island Rendered Flush at y = 0!
                    BoringNotchInteractiveIsland(manager: notch, isPreviewInsideDashboard: true)
                }
                .frame(height: notch.isExpanded ? 295 : 135)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .animation(.spring(response: 0.36, dampingFraction: 0.78), value: notch.isExpanded)
            }

            // Customization & Quick Action Controls Grid
            HStack(alignment: .top, spacing: 18) {
                // Theme & Geometry Customizer
                VStack(alignment: .leading, spacing: 14) {
                    Text("🎨 BoringNotch Görsel & Geometri Özelleştirme")
                        .font(.headline)

                    Picker("Neon / OLED Tema:", selection: $notch.glowTheme) {
                        ForEach(NotchGlowTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }

                    HStack {
                        Text("Kanat Genişliği: +\(Int(notch.wingExtraWidth)) px")
                            .font(.caption.monospaced())
                        Slider(value: $notch.wingExtraWidth, in: 90...200)
                    }

                    Toggle("İmleç Üzerine Gelince Otomatik Aç (Hover Expansion)", isOn: $notch.expandOnHover)

                    HStack(spacing: 10) {
                        Button(notch.isNotchEnabled ? "Üst Ekran Çentiğini Gizle" : "Üst Ekran Çentiğini Göster") {
                            if notch.isNotchEnabled { notch.hideNotchOverlay() } else { notch.showNotchOverlay() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)

                        Button(dock.isDockWidgetVisible ? "Dock Widget'ı Kapat" : "ExtraDock Widget'ı Aç") {
                            dock.toggleFloatingDockWidget()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.teal)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity)
                .liquidGlassCard(accent: notch.glowTheme.colors.first ?? .purple)

                // Interactive HUD & Notch State Triggers
                VStack(alignment: .leading, spacing: 14) {
                    Text("⚡ Çentik HUD & Sekme Hızlı Test Merkezi")
                        .font(.headline)
                    Text("macOS'in ekran ortasında çıkan kaba gri ses/parlaklık kutusu yerine çentik kanatlarında açılan animasyonlu HUD'ları test edin:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        Button("🔓 Face ID Kilit Açma Pod'u") {
                            notch.setExpanded(false)
                            faceID.performQuickFaceScan()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)

                        Button("📸 Kameradan Yüzümü Kaydet") {
                            faceID.enrollCurrentFaceFromCamera()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)

                        Button("🔊 Ses HUD (%80)") {
                            notch.setExpanded(false)
                            notch.triggerHUD(icon: "speaker.wave.3.fill", title: "Ses %80", value: 0.80)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)

                        Button("☀️ Parlaklık HUD (%90)") {
                            notch.setExpanded(false)
                            notch.triggerHUD(icon: "sun.max.fill", title: "Ekran %90", value: 0.90)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)

                        Button("📸 Ayna & Face ID Sekmesi") {
                            notch.activeTab = .mirror
                            notch.setExpanded(true)
                        }
                        .buttonStyle(.bordered)

                        Button("🕵️ Omuz Sörfü Uyarısı Testi") {
                            notch.setExpanded(false)
                            faceID.simulateShoulderSurfingToggle()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity)
                .liquidGlassCard(accent: .cyan)
            }

            // Dedicated Face ID Biometric & Lottie Studio Card right inside the Dynamic Island Studio
            FaceIDBiometricStudioCard(faceID: faceID, notch: notch)
        }
    }
}

public struct FaceIDBiometricStudioCard: View {
    @ObservedObject var faceID: FaceIDVisionManager
    @ObservedObject var notch: DynamicIslandNotchManager
    @State private var keychainPasswordInput: String = ""

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 22) {
                // Left: Live Webcam Feed + 3D Apple Face ID Vector Animation
                ZStack {
                    if faceID.isCameraRunning {
                        LiveCameraMirrorPreview(session: faceID.captureSession)
                            .frame(width: 155, height: 155)
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    } else {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.black.opacity(0.65))
                            .frame(width: 155, height: 155)
                    }

                    AppleFaceIDAnimatedGlyph(state: faceID.scanState, size: 96)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(
                            faceID.shoulderSurfingAlert ? Color.red : (faceID.scanState == .authenticated ? Color.green : Color.cyan),
                            lineWidth: 2
                        )
                )

                // Center: Biometric Telemetry & Enrollment Controls
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("08. Glance + FaceGate Gerçek Yüz Tanıma & Kilit Açma Motoru")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                        Spacer()
                        Text(faceID.hasEnrolledFace ? "✅ Yüz Kayıtlı: \(faceID.enrolledUserName)" : "⚠️ Yüz Kaydı Yok")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(faceID.hasEnrolledFace ? Color.green.opacity(0.22) : Color.orange.opacity(0.22))
                            .foregroundStyle(faceID.hasEnrolledFace ? .green : .orange)
                            .clipShape(Capsule())

                        Text(faceID.hasKeychainPasswordSaved ? "🔑 Keychain Hazır" : "🔑 Parola Girilmedi")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(faceID.hasKeychainPasswordSaved ? Color.cyan.opacity(0.22) : Color.gray.opacity(0.22))
                            .foregroundStyle(faceID.hasKeychainPasswordSaved ? .cyan : .secondary)
                            .clipShape(Capsule())
                    }

                    Text(faceID.statusText)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(.cyan)

                    HStack(spacing: 16) {
                        Label("Benzerlik: %\(String(format: "%.1f", faceID.matchSimilarityPercent))", systemImage: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                        Label("Göz EAR: \(String(format: "%.2f", faceID.lastEARValue)) (Kırpma: \(faceID.blinkCountInSession))", systemImage: "eye.fill")
                            .foregroundStyle(.cyan)
                        Label("Baş Açısı: \(String(format: "%.0f°", faceID.headYawDegrees))", systemImage: "person.fill.viewfinder")
                            .foregroundStyle(.purple)
                        Label("Algılanan Yüz: \(faceID.detectedFaceCount)", systemImage: "person.2.fill")
                            .foregroundStyle(faceID.shoulderSurfingAlert ? .red : .white)
                    }
                    .font(.system(size: 11, weight: .bold, design: .monospaced))

                    HStack(spacing: 10) {
                        Button(faceID.isCameraRunning ? "📹 Kamerayı Durdur" : "📹 Canlı Kamerayı Başlat") {
                            if faceID.isCameraRunning { faceID.stopLiveCamera() } else { faceID.startLiveCamera() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(faceID.isCameraRunning ? .gray : .blue)

                        Button("🧬 1. Yüzümü Kaydet (68-Landmark + Vision)") {
                            faceID.enrollCurrentFaceFromCamera()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)

                        Button("🛡️ 2. Uygulama Kilit Kalkanını Test Et (FaceGate)") {
                            faceID.simulateAppLockChallenge()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)

                        Button("🔒 3. Mac Ekranını Şimdi Kilitle") {
                            faceID.lockMacScreenNow()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                }
            }

            Divider().background(Color.white.opacity(0.12))

            // Real Unlock Mechanisms: Keychain Password + CGEvent Lock Screen Auto-Typer + FaceGate App Shield
            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("🔑 1. macOS Kilit Ekranı Otomatik Parola Yazıcı (jonnyoo/glance Mimarisi)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Mac uykudan uyandığında (`screensDidWake`) veya kilit ekranında yüzünüz doğrulandığı anda Keychain'deki parolanızı `CGEvent` ile milisaniyede yazıp Enter'a basar:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        SecureField("Mac oturum açma parolanız (AES Keychain'de şifrelenir)...", text: $keychainPasswordInput)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 300)

                        Button("🔐 Keychain'e Kaydet") {
                            faceID.savePasswordToKeychain(keychainPasswordInput)
                            keychainPasswordInput = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)

                        Button("🎨 Özel Lottie (.json) Seç") {
                            let panel = NSOpenPanel()
                            panel.allowedContentTypes = [.json]
                            if panel.runModal() == .OK, let url = panel.url {
                                faceID.customLottieFilePath = url.path
                                faceID.statusText = "✨ Özel Lottie animasyonu bağlandı: \(url.lastPathComponent)"
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Uyanınca Yüz Tanı ve Parolayı Otomatik Yaz (Glance)", isOn: $faceID.isScreenUnlockEnabled)
                        .font(.caption.bold())
                    Toggle("Korumalı Uygulamalarda Tam Ekran FaceGate Kalkanı", isOn: $faceID.isAppLockerEnabled)
                        .font(.caption.bold())
                    Toggle("Masadan Kalkınca (10sn Yüz Yoksa) Mac'i Otomatik Kilitle", isOn: $faceID.autoLockWhenWalkAway)
                        .font(.caption.bold())
                }
            }
        }
        .padding(20)
        .liquidGlassCard(accent: .green, cornerRadius: 22)
    }
}

// MARK: - 1. Bento Overview Panel (All 21 Modules + Live Hero Cards)
public struct BentoOverviewPanel: View {
    @ObservedObject var hubState = HubDashboardState.shared
    @ObservedObject var stats = StatsEngine.shared
    @ObservedObject var eney = EneyAIAgentManager.shared
    @ObservedObject var organizer = AIFileOrganizerManager.shared
    @ObservedObject var perms = PermissionsManager.shared

    public var filteredModules: [ModuleDescriptor] {
        if hubState.searchFilter.trimmingCharacters(in: .whitespaces).isEmpty {
            return ModuleDescriptor.all
        }
        return ModuleDescriptor.all.filter {
            $0.title.localizedCaseInsensitiveContains(hubState.searchFilter) ||
            $0.subtitle.localizedCaseInsensitiveContains(hubState.searchFilter) ||
            $0.openSourceBase.localizedCaseInsensitiveContains(hubState.searchFilter)
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bento Kontrol Merkezi (21 Modül)")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                    Text("Kullanmadığınız modülü tek tıkla kapatarak arka plan tüketimini 0 CPU / 0 RAM'e düşürün.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                TextField("21 modül veya açık kaynak repo ara...", text: $hubState.searchFilter)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 260)
            }

            // 4 Quick Bento Metric Cards
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
                BentoHeroMetricCard(
                    title: "Dinamik Ada (BoringNotch)",
                    value: "Canlı & Aktif",
                    subtitle: "QuadCurve OLED Çentik",
                    icon: "rectangle.topthird.inset.filled",
                    color: .pink
                ) {
                    hubState.selectedSection = .notchStudio
                }

                BentoHeroMetricCard(
                    title: "CPU & Bellek (Stats)",
                    value: "%\(Int(stats.cpuUsagePercent)) • \(String(format: "%.1f", stats.memoryUsedGB))GB",
                    subtitle: stats.thermalStateLabel,
                    icon: "cpu.fill",
                    color: .cyan
                ) {
                    hubState.selectedSection = .statsMonitor
                }

                BentoHeroMetricCard(
                    title: "Eney OS Ajanı",
                    value: eney.activeContext.appName,
                    subtitle: "Model: \(eney.selectedModel)",
                    icon: "wand.and.stars",
                    color: .purple
                ) {
                    hubState.selectedSection = .eneyAI
                }

                BentoHeroMetricCard(
                    title: "AI Dosya Düzenleyici",
                    value: "\(organizer.proposals.count) Dosya",
                    subtitle: "Magika + Vision OCR + LLM",
                    icon: "folder.fill.badge.gearshape",
                    color: .indigo
                ) {
                    organizer.scanFolder()
                    hubState.selectedSection = .aiFileOrganizer
                }
            }

            // 21 Modules Grid
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(filteredModules) { mod in
                    let isOn = hubState.isModuleEnabled(mod.id)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: mod.icon)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(
                                    LinearGradient(
                                        colors: [mod.accentColor, mod.accentColor.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("#\(String(format: "%02d", mod.number)) • \(mod.title)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                                Text(mod.openSourceBase)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(mod.accentColor)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { isOn },
                                set: { _ in hubState.toggleModule(mod.id) }
                            ))
                            .toggleStyle(.switch)
                            .controlSize(.small)
                        }

                        Text(mod.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .frame(height: 32, alignment: .topLeading)

                        HStack {
                            Text(mod.license)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(mod.accentColor.opacity(0.18))
                                .foregroundStyle(mod.accentColor)
                                .clipShape(Capsule())
                            Spacer()
                            Text(mod.shortcutHint)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(15)
                    .liquidGlassCard(accent: isOn ? mod.accentColor : .gray, cornerRadius: 16)
                }
            }
        }
    }
}

public struct BentoHeroMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                    Spacer()
                    Image(systemName: "arrow.up.right.circle.fill")
                        .foregroundStyle(.white.opacity(0.35))
                }
                Text(value)
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(color)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlassCard(accent: color, cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 2. Eney AI & Wand Panel
public struct EneyAIPanelView: View {
    @ObservedObject var eney = EneyAIAgentManager.shared
    @State private var chatInput: String = ""

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("01. Eney Proaktif OS Ajanı & Eney Wand (⌥ + W)")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                    Text("Açık Kaynak Çekirdek: neur0map/PikoChan + steipete/AXorcist + AaronRoeF/apple-mcp + Tinycast")
                        .font(.caption)
                        .foregroundStyle(.purple)
                }
                Spacer()
                Picker("AI Modeli", selection: $eney.selectedModel) {
                    ForEach(eney.availableModels, id: \.self) { m in
                        Text(m).tag(m)
                    }
                }
                .frame(width: 240)
                Button("Modelleri Yenile") {
                    eney.discoverLocalOllamaModels()
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("👁️ Eney Visual Agent & Çift ⌥ Option Spotlight Başlatıcı (Castor + Tinycast + AXorcist)")
                        .font(.caption.bold())
                        .foregroundStyle(.cyan)
                    Text("Aktif Uygulama: \(eney.activeContext.appName) • Açık Pencere: \(eney.activeContext.onScreenWindowList.count) • Ekran Vision OCR: \(eney.activeContext.screenOCRLineCount) satır")
                        .font(.caption)
                    Toggle("Klavyeden Çift ⌥ Option (veya ⌥ + Space) Basınca Yüzen Eney Spotlight Çubuğunu Aç", isOn: $eney.isOptionSpotlightEnabled)
                        .font(.caption2.bold())
                        .foregroundStyle(.purple)
                }
                Spacer()
                Button("🚀 Yüzen Eney Spotlight'ı Şimdi Aç (⌥)") {
                    eney.showSpotlightOverlay()
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)

                Button("👁️ Ekranda Ne Var Analiz Et") {
                    eney.analyzeWhatsOnMyScreenNow()
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)

                Button("☀️ Sabah Özeti") {
                    eney.executeWorkflow(key: "morning_brief")
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .liquidGlassCard(accent: .cyan, cornerRadius: 16)

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("💬 Eney Proaktif Asistan Sohbeti")
                        .font(.headline)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(eney.messages) { msg in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(msg.role == "user" ? "Sen" : (msg.role == "proactive" ? "⚡ Eney Proaktif Müdahale" : "🤖 Eney AI"))
                                        .font(.caption.bold())
                                        .foregroundStyle(msg.role == "user" ? .cyan : .purple)
                                    Text(msg.text)
                                        .font(.system(size: 13))
                                    if let actionTitle = msg.actionTitle, let key = msg.actionKey {
                                        Button(actionTitle) {
                                            eney.executeWorkflow(key: key)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.purple)
                                        .controlSize(.small)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(msg.role == "user" ? Color.cyan.opacity(0.12) : Color.purple.opacity(0.14))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .frame(height: 310)

                    HStack {
                        TextField("Eney'e sor veya sistem komutu ver (Örn: RAM durumunu analiz et, İndirilenleri düzenle)...", text: $chatInput)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                eney.sendUserPrompt(chatInput)
                                chatInput = ""
                            }
                        Button(eney.isGenerating ? "Düşünüyor..." : "Gönder") {
                            eney.sendUserPrompt(chatInput)
                            chatInput = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .disabled(eney.isGenerating)
                    }
                }
                .padding(18)
                .liquidGlassCard(accent: .purple)

                VStack(alignment: .leading, spacing: 12) {
                    Text("🪄 Eney Wand & Spell (Metin & Gizlilik Aracı)")
                        .font(.headline)
                    Text("Seçili metni özetler, imlasını düzeltir ya da ekran paylaşımı öncesi IBAN / Kredi Kartı / API anahtarlarını maskeler.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextEditor(text: $eney.wandInputText)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    HStack(spacing: 8) {
                        Button("🔒 Hassas Verileri Maskele") {
                            eney.runWandAction("mask_pii")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .controlSize(.small)

                        Button("📌 Özetle") {
                            eney.runWandAction("summarize")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button("✨ İmla Düzelt") {
                            eney.runWandAction("polish")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    Text("Çıktı:")
                        .font(.caption.bold())
                    TextEditor(text: $eney.wandOutputText)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(width: 410)
                .padding(18)
                .liquidGlassCard(accent: .orange)
            }
        }
    }
}

// MARK: - 3. AI File Organizer Panel
public struct AIFileOrganizerPanelView: View {
    @ObservedObject var organizer = AIFileOrganizerManager.shared

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("02. AI Dosya Düzenleyici & Kargaşa Önleyici")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                    Text("3 Katmanlı Analiz: Google Magika Byte İmzası + Apple Vision OCR / PDFKit + Semantik İsimlendirme")
                        .font(.caption)
                        .foregroundStyle(.indigo)
                }
                Spacer()
                if !organizer.undoHistory.isEmpty {
                    Button("↩️ Son Taşımayı Geri Al (Undo)") {
                        organizer.undoLastBatch()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }

            HStack(spacing: 10) {
                TextField("Hedef Klasör Yolu", text: $organizer.targetFolderPath)
                    .textFieldStyle(.roundedBorder)
                Button("~/Downloads") {
                    organizer.scanFolder(path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads").path)
                }
                .buttonStyle(.bordered)
                Button("~/Desktop") {
                    organizer.scanFolder(path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop").path)
                }
                .buttonStyle(.bordered)
                Button("🔍 Klasörü Analiz Et (Dry-Run)") {
                    organizer.scanFolder()
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)

                Button("✅ Onaylananları Taşı") {
                    organizer.applyApprovedProposals()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(organizer.proposals.isEmpty)
            }
            .padding(16)
            .liquidGlassCard(accent: .indigo, cornerRadius: 16)

            Text(organizer.statusMessage)
                .font(.caption.bold())
                .foregroundStyle(.cyan)

            VStack(alignment: .leading, spacing: 8) {
                ForEach($organizer.proposals) { $item in
                    HStack(spacing: 12) {
                        Toggle("", isOn: $item.isApproved)
                            .labelsHidden()

                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(item.originalFilename)
                                    .font(.system(size: 13, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(item.semanticCategory)/\(item.suggestedFilename)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.green)
                            }
                            Text("Tür: \(item.detectedMimeOrSignature) • Neden: \(item.reason)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("%\(Int(item.confidence * 100))")
                            .font(.caption.monospaced().bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.indigo.opacity(0.25))
                            .clipShape(Capsule())
                    }
                    .padding(12)
                    .liquidGlassCard(accent: .indigo, cornerRadius: 12)
                }
            }
        }
    }
}

// MARK: - 4. Nashi File Toolkit Panel (orkunisitmak/nashi-app + Shift-Click 360° Radial Action Wheel)
public struct NashiToolkitPanelView: View {
    @ObservedObject var nashi = NashiToolkitManager.shared

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("03. Nashi File Toolkit & 360° Shift+Click Eylem Çarkı")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                    Text("orkunisitmak/nashi-app Mimarisi: Finder'da bir dosyaya ⇧ Shift ile tıkladığınızda / sürüklediğinizde imleçte açılan özelleştirilmiş Cyber-Glass Çark")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                Spacer()
                Button("🍐 İmleçte Yüzen Çarkı Şimdi Aç (⇧+Tık)") {
                    nashi.showRadialWheelAtCursor()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Button("📂 Finder Seçimini Yakala") {
                    nashi.captureFinderSelectionOrDragPasteboard()
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
            }

            HStack(alignment: .top, spacing: 20) {
                // Left Column: Live Interactive 360° Radial Action Wheel Studio
                VStack(alignment: .center, spacing: 12) {
                    HStack {
                        Text("🎡 Canlı 360° Nashi Radyal Çark Önizlemesi")
                            .font(.headline)
                        Spacer()
                        Picker("Tema", selection: $nashi.wheelTheme) {
                            ForEach(NashiWheelTheme.allCases) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                        .frame(width: 210)
                    }

                    NashiRadialWheelView(manager: nashi, isFloatingPopup: false)

                    VStack(alignment: .leading, spacing: 6) {
                        Toggle("Finder'da ⇧ Shift + Sağ Tık / Sürükle ile Çarkı İmleçte Aç (nashi-app)", isOn: $nashi.isShiftClickWheelEnabled)
                            .font(.caption.bold())
                        Toggle("🛡️ ⇧ Shift + Sağ Tık Yapınca macOS Sistem Menüsünü Engelle (CGEventTap)", isOn: $nashi.blockSystemContextMenuOnShiftRightClick)
                            .font(.caption.bold())
                            .foregroundStyle(.cyan)
                        Text("💡 İpucu: Çarkın tam ortasındaki dosya ikonuna tıklayarak, üstteki sekmelere basarak veya klavyeden Tab / 1-2-3 / ⌘ / ⌃ tuşlarıyla seçenek halkalarını anında değiştirebilirsiniz!")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(width: 455)
                .padding(18)
                .liquidGlassCard(accent: nashi.wheelTheme.primaryColor)

                // Right Column: File Selector, Format Converter, Vision Remove BG, Web Downloader & QR Studio
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🖼️ Seçili Dosya, Format Dönüştürücü & Vision AI Arka Plan Silici")
                            .font(.headline)

                        HStack {
                            TextField("Görsel/dosya yolu seçin veya Finder'da Shift+Tıklayın...", text: $nashi.selectedFilePath)
                                .textFieldStyle(.roundedBorder)
                            Button("Dosya Seç...") {
                                let panel = NSOpenPanel()
                                panel.allowsMultipleSelection = false
                                panel.canChooseDirectories = false
                                if panel.runModal() == .OK, let url = panel.url {
                                    nashi.selectedFilePath = url.path
                                    nashi.readQRCode(from: url)
                                }
                            }
                        }

                        HStack {
                            Picker("Hedef Format", selection: $nashi.targetFormat) {
                                ForEach(["PNG", "JPEG", "TIFF", "BMP", "PDF"], id: \.self) { fmt in
                                    Text(fmt).tag(fmt)
                                }
                            }
                            .frame(width: 170)

                            Slider(value: $nashi.jpegQuality, in: 0.2...1.0)
                            Text("Kalite: %\(Int(nashi.jpegQuality * 100))")
                                .font(.caption.monospaced())
                        }

                        HStack(spacing: 8) {
                            Button("🔄 Dönüştür") {
                                nashi.convertSelectedFile()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)

                            Button("✨ Arka Planı Sil (Vision AI)") {
                                nashi.removeBackgroundFromSelectedImage()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)

                            Button("📝 OCR Metin Kopyala") {
                                nashi.extractTextViaVisionOCR()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.cyan)

                            Button("🏝️ Dinamik Ada'ya At") {
                                nashi.sendSelectedFileToDynamicIslandShelf()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.pink)
                        }

                        Text(nashi.conversionStatus)
                            .font(.caption.bold())
                            .foregroundStyle(.green)

                        Divider()

                        Text("🌐 Web Medya & Video İndirici (yt-dlp / Direct)")
                            .font(.headline)
                        HStack {
                            TextField("https://... medya veya dosya bağlantısı", text: $nashi.mediaURLString)
                                .textFieldStyle(.roundedBorder)
                            Button(nashi.isDownloading ? "İndiriliyor..." : "⬇️ İndir") {
                                nashi.downloadWebMedia()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.cyan)
                        }
                        Text(nashi.downloadStatus)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(18)
                    .liquidGlassCard(accent: .orange)

                    // QR Code Reader & Generator Card
                    HStack(alignment: .center, spacing: 16) {
                        if let qrImg = nashi.generatedQRImage {
                            Image(nsImage: qrImg)
                                .interpolation(.none)
                                .resizable()
                                .frame(width: 120, height: 120)
                                .padding(6)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("🔳 QR Kod Okuyucu & Üretici Stüdyosu")
                                .font(.headline)
                            HStack {
                                TextField("QR içeriği veya URL...", text: $nashi.qrInputText)
                                    .textFieldStyle(.roundedBorder)
                                Button("Üret") {
                                    nashi.generateQRCode()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.purple)
                            }
                            if !nashi.decodedQRText.isEmpty {
                                Text("Okunan QR: \(nashi.decodedQRText)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                    .padding(18)
                    .liquidGlassCard(accent: .purple)
                }
            }

            // Native macOS Finder Right-Click Context Menu ("Hızlı Eylemler >") Studio Card
            NativeFinderContextMenuStudioCard(nashi: nashi)
        }
    }
}

// MARK: - 5. Stats System Monitor Panel (Custom Sparklines + Live MenuBar Popup Preview + Per-Core Bars)
public struct StatsMonitorPanelView: View {
    @ObservedObject var stats = StatsEngine.shared

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("04. Stats Sistem Monitörü & Menü Çubuğu Popup Stüdyosu")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                    Text("exelban/stats v2.11 Mimarisi: Sağ üst menü çubuğuna tıkladığınızda açılan grafiksel pencere + Tam ekran telemetri")
                        .font(.caption)
                        .foregroundStyle(.cyan)
                }
                Spacer()
                Button("Şimdi Yenile") {
                    stats.sampleAllMetrics()
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
            }

            HStack(alignment: .top, spacing: 20) {
                // Left: Live Interactive Menu Bar Popup Preview (Exact replica of what opens in the Menu Bar)
                VStack(alignment: .leading, spacing: 8) {
                    Text("📌 Menü Çubuğu Açılır Penceresi (Canlı Önizleme)")
                        .font(.caption.bold())
                        .foregroundStyle(.cyan)
                    StatsMenuBarPopupView()
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(Color.cyan.opacity(0.45), lineWidth: 1.2)
                        )
                        .shadow(color: .black.opacity(0.5), radius: 16)
                }

                // Right: Expanded Bento Telemetry & Process Freezer
                VStack(alignment: .leading, spacing: 16) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("CPU Yükü (\(stats.cpuCoreCount) Çekirdek)")
                                    .font(.headline)
                                Spacer()
                                Text("%\(String(format: "%.1f", stats.cpuUsagePercent))")
                                    .font(.system(size: 20, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(.cyan)
                            }
                            Text("User: %\(String(format: "%.1f", stats.cpuUserPercent)) • Sys: %\(String(format: "%.1f", stats.cpuSystemPercent)) • Load: \(stats.loadAverageString)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            SparklineAreaChart(values: stats.cpuHistory, color: .cyan)
                                .frame(height: 64)
                        }
                        .padding(16)
                        .liquidGlassCard(accent: .cyan)

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Bellek (RAM)")
                                    .font(.headline)
                                Spacer()
                                Text("\(String(format: "%.1f", stats.memoryUsedGB))/\(Int(stats.memoryTotalGB)) GB")
                                    .font(.system(size: 18, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(.purple)
                            }
                            Text("App: \(String(format: "%.1f", stats.memoryAppGB))G • Wired: \(String(format: "%.1f", stats.memoryWiredGB))G • Cmp: \(String(format: "%.1f", stats.memoryCompressedGB))G")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            SparklineAreaChart(values: stats.memoryHistory, color: .purple)
                                .frame(height: 64)
                        }
                        .padding(16)
                        .liquidGlassCard(accent: .purple)
                    }

                    Text("🔥 En Çok Kaynak Tüketen Süreçler & Akıllı Dondurucu (SIGSTOP / SIGCONT)")
                        .font(.headline)

                    VStack(spacing: 8) {
                        ForEach(stats.topProcesses) { proc in
                            HStack {
                                Text("PID \(proc.pid)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 70, alignment: .leading)
                                Text(proc.name)
                                    .font(.system(size: 13, weight: .bold))
                                    .lineLimit(1)
                                Spacer()
                                Text("CPU: %\(String(format: "%.1f", proc.cpuPercent))")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.cyan)
                                    .frame(width: 85, alignment: .trailing)
                                Text("RAM: \(String(format: "%.0f", proc.memoryMB)) MB")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.green)
                                    .frame(width: 85, alignment: .trailing)

                                Button(proc.isSuspended ? "▶️ Devam" : "❄️ Dondur") {
                                    stats.toggleSuspendProcess(pid: proc.pid)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(proc.isSuspended ? .green : .indigo)
                                .controlSize(.small)
                            }
                            .padding(10)
                            .liquidGlassCard(accent: proc.isSuspended ? .orange : .cyan, cornerRadius: 12)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 6. Mouse Fix & Window Loop Panel
public struct MouseAndWindowPanelView: View {
    @ObservedObject var mouse = MouseFixManager.shared
    @ObservedObject var winLoop = WindowLoopManager.shared

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("05. Mouse Fix (LinearMouse/Mos) & 13. Window Loop (Rectangle/Loop)")
                .font(.system(size: 24, weight: .heavy, design: .rounded))

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("🖱️ Harici Mouse Sorun Çözücü")
                        .font(.headline)
                    Text(mouse.statusText)
                        .font(.caption)
                        .foregroundStyle(.cyan)

                    Toggle("Trackpad Doğal Kaydırmayı Bozmadan Harici Mouse Yönünü Ters Çevir", isOn: $mouse.invertExternalMouseScroll)
                    HStack {
                        Text("Smooth Scroll Çarpanı: \(String(format: "%.2fx", mouse.smoothScrollMultiplier))")
                            .font(.caption)
                        Slider(value: $mouse.smoothScrollMultiplier, in: 0.5...3.0)
                    }
                    Picker("Yan Tuş 4 Görevi:", selection: $mouse.sideButton4Action) {
                        ForEach(mouse.availableButtonActions, id: \.self) { act in Text(act).tag(act) }
                    }
                    Picker("Yan Tuş 5 Görevi:", selection: $mouse.sideButton5Action) {
                        ForEach(mouse.availableButtonActions, id: \.self) { act in Text(act).tag(act) }
                    }

                    HStack {
                        Button(mouse.isEnabled ? "Mouse Fix'i Durdur" : "🚀 Mouse Fix'i Başlat (CGEventTap)") {
                            if mouse.isEnabled { mouse.stopMouseFix() } else { mouse.startMouseFix() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(mouse.isEnabled ? .red : .blue)
                        Spacer()
                        Text("Yakalanan Tekerlek Olayı: \(mouse.totalInterceptedScrollEvents)")
                            .font(.caption2.monospaced())
                    }
                }
                .padding(18)
                .liquidGlassCard(accent: .blue)

                VStack(alignment: .leading, spacing: 12) {
                    Text("🪟 Window Loop & Hızlı Pencere Bölücü")
                        .font(.headline)
                    Text(winLoop.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(WindowSnapPosition.allCases) { pos in
                            Button {
                                winLoop.snapFocusedWindow(to: pos)
                            } label: {
                                Label(pos.rawValue, systemImage: pos.icon)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.indigo)
                        }
                    }
                }
                .frame(width: 400)
                .padding(18)
                .liquidGlassCard(accent: .indigo)
            }
        }
    }
}

// MARK: - 7. Utilities Vault Panel
public struct UtilitiesVaultPanelView: View {
    @ObservedObject var clipboard = ClipboardVaultManager.shared
    @ObservedObject var utils = SystemUtilitiesManager.shared

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("09–21. Birleştirilmiş Sistem & Üretkenlik Araçları")
                .font(.system(size: 24, weight: .heavy, design: .rounded))

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("📋 12. Akıllı Pano Kasası (Maccy — Şifre Filtreli)")
                        .font(.headline)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(clipboard.entries) { entry in
                                HStack {
                                    Text(entry.content)
                                        .font(.caption)
                                        .lineLimit(2)
                                    Spacer()
                                    Button("Kopyala") {
                                        clipboard.copyToPasteboard(entry)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
                                }
                                .padding(8)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .frame(height: 210)
                }
                .padding(18)
                .liquidGlassCard(accent: .yellow)

                VStack(alignment: .leading, spacing: 10) {
                    Text("🎨 17. TRex Renk Seçici + 18. Caffeinate + 16. Pearcleaner")
                        .font(.headline)
                    HStack {
                        Button("💉 Ekrandan Renk Seç (NSColorSampler)") {
                            utils.pickScreenColor()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.mint)
                        Text("\(utils.pickedHexColor)")
                            .font(.caption.monospaced().bold())
                    }

                    HStack {
                        Button(utils.isKeepAwakeActive ? "☕ Uyanık Tutucu Aktif" : "☕ Mac'i Uyanık Tut (KeepAwake)") {
                            utils.toggleKeepAwake()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(utils.isKeepAwakeActive ? .green : .brown)

                        Button("🧹 30sn Klavye Temizlik Kilidi") {
                            utils.startCleanShield(seconds: 30)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)

                        Button(utils.isKeyCastrActive ? "⌨️ Tuş: \(utils.lastKeystrokeDisplay)" : "⌨️ KeyCastr Başlat") {
                            utils.toggleKeyCastr()
                        }
                        .buttonStyle(.bordered)
                    }

                    Divider()
                    Text("🗑️ 16. Pearcleaner Yetim Önbellek Tarayıcı (Toplam: \(String(format: "%.1f", utils.totalCacheMB)) MB)")
                        .font(.subheadline.bold())
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(utils.discoveredCaches.prefix(6)) { cache in
                                HStack {
                                    Text(cache.name).font(.caption)
                                    Spacer()
                                    Text("\(String(format: "%.1f", cache.sizeMB)) MB")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.pink)
                                }
                            }
                        }
                    }
                    .frame(height: 90)
                }
                .padding(18)
                .liquidGlassCard(accent: .mint)
            }
        }
    }
}
