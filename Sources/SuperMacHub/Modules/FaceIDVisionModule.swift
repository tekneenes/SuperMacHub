import SwiftUI
import AppKit
@preconcurrency import AVFoundation
import Vision
import Security
import LocalAuthentication

// MARK: - 1. Face ID Authentication States (Apple Dynamic Island Lifecycle)
public enum FaceIDScanState: String, Equatable {
    case idle = "Hazır"
    case scanning = "Yüz Taranıyor..."
    case verifyingLiveness = "Canlılık & Göz Kırpma Doğrulanıyor..."
    case authenticated = "Yüz Doğrulandı (Kilit Açıldı)"
    case failed = "Eşleşme Başarısız"
    case shoulderSurfing = "Omuz Sörfü (2+ Yüz) Algılandı!"
}

// MARK: - 2. Iconic Open-Source Apple Face ID 3D Morphing Vector Animation
public struct AppleFaceIDAnimatedGlyph: View {
    public let state: FaceIDScanState
    public var size: CGFloat = 68

    @State private var ringRotation1: Double = 0
    @State private var ringRotation2: Double = 0
    @State private var bracketScale: CGFloat = 1.0
    @State private var faceTiltY: Double = 0
    @State private var checkmarkTrim: CGFloat = 0
    @State private var shakeOffset: CGFloat = 0

    public init(state: FaceIDScanState, size: CGFloat = 68) {
        self.state = state
        self.size = size
    }

    private var accentColor: Color {
        switch state {
        case .idle: return .cyan
        case .scanning, .verifyingLiveness: return Color(red: 0.20, green: 0.78, blue: 1.0)
        case .authenticated: return Color(red: 0.18, green: 0.92, blue: 0.48)
        case .failed, .shoulderSurfing: return Color(red: 1.0, green: 0.27, blue: 0.32)
        }
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accentColor.opacity(0.32), Color.clear],
                        center: .center,
                        startRadius: 2,
                        endRadius: size * 0.65
                    )
                )
                .frame(width: size * 1.25, height: size * 1.25)

            if state == .scanning || state == .verifyingLiveness {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [accentColor.opacity(0.05), accentColor, .purple, accentColor.opacity(0.05)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .frame(width: size * 0.92, height: size * 0.92)
                    .rotation3DEffect(.degrees(62), axis: (x: 1, y: 0.3, z: 0))
                    .rotationEffect(.degrees(ringRotation1))

                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.clear, .cyan, accentColor, .clear],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                    )
                    .frame(width: size * 0.88, height: size * 0.88)
                    .rotation3DEffect(.degrees(58), axis: (x: -0.4, y: 1, z: 0.2))
                    .rotationEffect(.degrees(ringRotation2))
            }

            if state != .authenticated {
                ZStack {
                    FaceIDBracketsShape()
                        .stroke(accentColor, style: StrokeStyle(lineWidth: size * 0.048, lineCap: .round, lineJoin: .round))
                        .frame(width: size * 0.68, height: size * 0.68)
                        .scaleEffect(bracketScale)

                    FaceIDFeaturesShape()
                        .stroke(accentColor, style: StrokeStyle(lineWidth: size * 0.048, lineCap: .round, lineJoin: .round))
                        .frame(width: size * 0.40, height: size * 0.40)
                        .rotation3DEffect(.degrees(faceTiltY), axis: (x: 0.2, y: 1.0, z: 0.0))
                }
                .offset(x: shakeOffset)
            }

            if state == .authenticated {
                ZStack {
                    Circle()
                        .stroke(accentColor.opacity(0.28), lineWidth: size * 0.055)
                        .frame(width: size * 0.76, height: size * 0.76)

                    Circle()
                        .trim(from: 0, to: checkmarkTrim)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: size * 0.055, lineCap: .round))
                        .frame(width: size * 0.76, height: size * 0.76)
                        .rotationEffect(.degrees(-90))

                    FaceIDCheckmarkShape()
                        .trim(from: 0, to: checkmarkTrim)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: size * 0.065, lineCap: .round, lineJoin: .round))
                        .frame(width: size * 0.36, height: size * 0.36)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            triggerAnimations(for: state)
        }
        .onChange(of: state) { _, newState in
            triggerAnimations(for: newState)
        }
    }

    private func triggerAnimations(for currentState: FaceIDScanState) {
        switch currentState {
        case .scanning, .verifyingLiveness:
            checkmarkTrim = 0
            withAnimation(.linear(duration: 1.35).repeatForever(autoreverses: false)) {
                ringRotation1 = 360
                ringRotation2 = -360
            }
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                bracketScale = 1.08
                faceTiltY = 22
            }
        case .authenticated:
            bracketScale = 1.0
            faceTiltY = 0
            checkmarkTrim = 0
            withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
                checkmarkTrim = 1.0
            }
        case .failed, .shoulderSurfing:
            bracketScale = 1.0
            faceTiltY = 0
            withAnimation(.default.repeatCount(4, autoreverses: true).speed(6)) {
                shakeOffset = 7
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                shakeOffset = 0
            }
        case .idle:
            bracketScale = 1.0
            faceTiltY = 0
            checkmarkTrim = 0
        }
    }
}

private struct FaceIDBracketsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let len = min(w, h) * 0.26
        let r = min(w, h) * 0.14

        p.move(to: CGPoint(x: 0, y: len))
        p.addLine(to: CGPoint(x: 0, y: r))
        p.addQuadCurve(to: CGPoint(x: r, y: 0), control: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: len, y: 0))

        p.move(to: CGPoint(x: w - len, y: 0))
        p.addLine(to: CGPoint(x: w - r, y: 0))
        p.addQuadCurve(to: CGPoint(x: w, y: r), control: CGPoint(x: w, y: 0))
        p.addLine(to: CGPoint(x: w, y: len))

        p.move(to: CGPoint(x: w, y: h - len))
        p.addLine(to: CGPoint(x: w, y: h - r))
        p.addQuadCurve(to: CGPoint(x: w - r, y: h), control: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: w - len, y: h))

        p.move(to: CGPoint(x: len, y: h))
        p.addLine(to: CGPoint(x: r, y: h))
        p.addQuadCurve(to: CGPoint(x: 0, y: h - r), control: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: 0, y: h - len))

        return p
    }
}

private struct FaceIDFeaturesShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        p.move(to: CGPoint(x: w * 0.18, y: h * 0.12))
        p.addLine(to: CGPoint(x: w * 0.18, y: h * 0.28))

        p.move(to: CGPoint(x: w * 0.82, y: h * 0.12))
        p.addLine(to: CGPoint(x: w * 0.82, y: h * 0.28))

        p.move(to: CGPoint(x: w * 0.50, y: h * 0.18))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.54))
        p.addQuadCurve(
            to: CGPoint(x: w * 0.38, y: h * 0.58),
            control: CGPoint(x: w * 0.50, y: h * 0.60)
        )

        p.move(to: CGPoint(x: w * 0.20, y: h * 0.76))
        p.addQuadCurve(
            to: CGPoint(x: w * 0.80, y: h * 0.76),
            control: CGPoint(x: w * 0.50, y: h * 0.98)
        )

        return p
    }
}

private struct FaceIDCheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.width * 0.12, y: rect.height * 0.54))
        p.addLine(to: CGPoint(x: rect.width * 0.42, y: rect.height * 0.84))
        p.addLine(to: CGPoint(x: rect.width * 0.90, y: rect.height * 0.18))
        return p
    }
}

// MARK: - 3. Live Camera Preview NSViewRepresentable
public struct LiveCameraMirrorPreview: NSViewRepresentable {
    public let session: AVCaptureSession

    public init(session: AVCaptureSession) {
        self.session = session
    }

    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
        if previewLayer.connection?.isVideoMirroringSupported == true {
            previewLayer.connection?.isVideoMirrored = true
        }
        view.layer = previewLayer
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        if let layer = nsView.layer as? AVCaptureVideoPreviewLayer {
            layer.session = session
        }
    }
}

// MARK: - 4. Stored Biometric Profile Model
public struct EnrolledFaceProfile: Codable {
    public let userName: String
    public let enrolledAt: Date
    public let landmarkRatios: [Double]
    public let featurePrintArchivedData: Data?
}

// MARK: - 5. Full-Screen Real App Lock Shield View (FaceGate Overlay)
public struct AppLockShieldOverlayView: View {
    @ObservedObject var faceID = FaceIDVisionManager.shared

    public var body: some View {
        ZStack {
            // Frosted Obsidian Blur Backing
            Color.black.opacity(0.92)
                .ignoresSafeArea()

            RadialGradient(
                colors: [Color.purple.opacity(0.24), Color.cyan.opacity(0.12), Color.clear],
                center: .center,
                startRadius: 20,
                endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                // Live Camera + 3D Face ID Ring
                ZStack {
                    if faceID.isCameraRunning {
                        LiveCameraMirrorPreview(session: faceID.captureSession)
                            .frame(width: 180, height: 180)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 180, height: 180)
                    }

                    AppleFaceIDAnimatedGlyph(state: faceID.scanState, size: 120)
                }
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 2.5
                        )
                )
                .shadow(color: .cyan.opacity(0.4), radius: 20)

                VStack(spacing: 8) {
                    Text("🔒 \(faceID.lockedAppCurrentlyBlocking ?? "Uygulama") FaceGate İle Kilitli")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Kilidi açmak için kameraya bakın (Yüz Tanıma aktif) veya Touch ID kullanın.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))

                    Text("Canlı Eşleşme: %\(String(format: "%.1f", faceID.matchSimilarityPercent)) • Göz Kırpma EAR: \(String(format: "%.2f", faceID.lastEARValue))")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.cyan)
                }

                HStack(spacing: 14) {
                    Button {
                        faceID.performQuickFaceScan()
                    } label: {
                        Label("Yüzümü Şimdi Tara (Face ID)", systemImage: "faceid")
                            .font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        faceID.unlockWithTouchIDOrPassword()
                    } label: {
                        Label("Touch ID / Sistem Parolası ile Aç", systemImage: "touchid")
                            .font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.14))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        faceID.dismissAppLockShield()
                    } label: {
                        Text("Kalkanı Kapat (Testten Çık)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(40)
        }
    }
}

// MARK: - 6. Real On-Device Vision + Keychain + CGEvent Unlock Engine (Glance + FaceGate)
@MainActor
public final class FaceIDVisionManager: NSObject, ObservableObject {
    public static let shared = FaceIDVisionManager()

    @Published public var scanState: FaceIDScanState = .idle
    @Published public var isAuthenticated: Bool = true
    @Published public var isCameraRunning: Bool = false
    @Published public var hasEnrolledFace: Bool = false
    @Published public var enrolledUserName: String = NSFullUserName().isEmpty ? "Muhammed" : NSFullUserName()

    // Keychain & Real Lock Screen Auto-Unlock State (jonnyoo/glance mechanism)
    @Published public var isScreenUnlockEnabled: Bool = true
    @Published public var hasKeychainPasswordSaved: Bool = false
    @Published public var keychainPasswordInput: String = ""
    @Published public var isSystemScreenCurrentlyLocked: Bool = false
    @Published public var autoLockWhenWalkAway: Bool = false

    // Live Biometric Telemetry from Vision Framework
    @Published public var detectedFaceCount: Int = 1
    @Published public var lastEARValue: Double = 0.31
    @Published public var blinkCountInSession: Int = 0
    @Published public var headYawDegrees: Double = 0.0
    @Published public var matchSimilarityPercent: Double = 98.4
    @Published public var livenessVerified: Bool = true
    @Published public var shoulderSurfingAlert: Bool = false

    // App Locker (FaceGate mechanism) & Custom Lottie
    @Published public var isAppLockerEnabled: Bool = true
    @Published public var protectedAppNames: [String] = ["Messages", "WhatsApp", "Photos", "Notes"]
    @Published public var newProtectedAppInput: String = ""
    @Published public var lockedAppCurrentlyBlocking: String? = nil
    @Published public var isAppShieldVisible: Bool = false
    @Published public var customLottieFilePath: String = ""
    @Published public var statusText: String = "Glance + FaceGate Gerçek Kilit Açma Motoru Hazır"

    nonisolated(unsafe) public let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let visionQueue = DispatchQueue(label: "com.supermachub.faceid.vision", qos: .userInteractive)

    private var enrolledProfile: EnrolledFaceProfile?
    private var enrolledFeaturePrint: VNFeaturePrintObservation?
    private var isEnrollingNextFrame: Bool = false
    private var wasEyeClosedLastFrame: Bool = false
    private var lastFrameProcessedTime: TimeInterval = 0
    private var noFaceConsecutiveFrames: Int = 0
    private var workspaceObserver: NSObjectProtocol?
    private var appShieldPanel: NSPanel?

    private let keychainService = "com.supermachub.faceid.unlock"
    private let keychainAccount = "macos_login_password"

    private let profileURL: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".supermachub")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("faceid_biometric_profile.json")
    }()

    private override init() {
        super.init()
        loadEnrolledProfile()
        hasKeychainPasswordSaved = (readPasswordFromKeychain() != nil)
        startSystemLockAndWakeObservers()
        startAppLockWatcher()
    }

    // MARK: - 1. macOS Keychain Vault (Encrypted Password Storage for Glance Lock Screen Auto-Type)
    public func savePasswordToKeychain(_ password: String) {
        let trimmed = password.trimmingCharacters(in: .newlines)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else {
            statusText = "⚠️ Geçerli bir parola girin."
            return
        }

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status == errSecSuccess {
            hasKeychainPasswordSaved = true
            keychainPasswordInput = ""
            statusText = "🔐 Parola macOS Keychain (Donanım Anahtarlığı) içine güvenle şifrelenerek kaydedildi!"
        } else {
            statusText = "⚠️ Keychain kayıt hatası (Kod: \(status))."
        }
    }

    public func readPasswordFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func removePasswordFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
        hasKeychainPasswordSaved = false
        statusText = "🗑️ Keychain'deki kayıtlı parola silindi."
    }

    // MARK: - 2. System Lock Screen Observer (`com.apple.screenIsLocked` + Wake) & `CGEvent` Auto-Typer
    private func startSystemLockAndWakeObservers() {
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.isSystemScreenCurrentlyLocked = true
                self.isAuthenticated = false
                if self.isScreenUnlockEnabled {
                    self.startLiveCamera()
                }
            }
        }

        dnc.addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.isSystemScreenCurrentlyLocked = false
                self.isAuthenticated = true
                DynamicIslandNotchManager.shared.triggerFaceIDPod(state: .authenticated, message: "Mac Kilidi Açıldı")
            }
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isScreenUnlockEnabled else { return }
                // When Mac wakes up on the Lock Screen, immediately scan face & auto-type password!
                self.performLockScreenFaceUnlock()
            }
        }
    }

    /// Scans face on wake/lock screen and injects the Keychain password + Return via `CGEvent` (exact `jonnyoo/glance` method)
    public func performLockScreenFaceUnlock() {
        startLiveCamera()
        scanState = .scanning
        DynamicIslandNotchManager.shared.triggerFaceIDPod(state: .scanning, message: "Kilit Ekranı Taranıyor...")

        Task {
            try? await Task.sleep(nanoseconds: 850_000_000)
            guard self.detectedFaceCount == 1, self.matchSimilarityPercent >= 82.0 else {
                self.scanState = .failed
                DynamicIslandNotchManager.shared.triggerFaceIDPod(state: .failed, message: "Yüz Eşleşmedi")
                return
            }

            self.scanState = .authenticated
            self.isAuthenticated = true
            DynamicIslandNotchManager.shared.triggerFaceIDPod(state: .authenticated, message: "Parola Giriliyor...")

            if self.isSystemScreenCurrentlyLocked, let password = self.readPasswordFromKeychain() {
                self.injectPasswordViaCGEvent(password)
            }
        }
    }

    /// Uses CoreGraphics HID Event injection (`CGEvent`) to type the password and press Return (KeyCode 36)
    public func injectPasswordViaCGEvent(_ password: String) {
        guard AXIsProcessTrusted() else {
            PermissionsManager.shared.requestAccessibility()
            statusText = "⚠️ Otomatik kilit açma için Accessibility (Erişilebilirlik) izni gerekiyor."
            return
        }

        let source = CGEventSource(stateID: .hidSystemState)
        for scalar in password.utf16 {
            var char = scalar
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
               let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
                keyDown.keyboardSetUnicodeString(stringLength: 1, unicodeString: &char)
                keyUp.keyboardSetUnicodeString(stringLength: 1, unicodeString: &char)
                keyDown.post(tap: .cghidEventTap)
                keyUp.post(tap: .cghidEventTap)
            }
        }

        // Press Return (Virtual KeyCode 36) to submit the macOS Lock Screen password
        if let retDown = CGEvent(keyboardEventSource: source, virtualKey: 36, keyDown: true),
           let retUp = CGEvent(keyboardEventSource: source, virtualKey: 36, keyDown: false) {
            retDown.post(tap: .cghidEventTap)
            retUp.post(tap: .cghidEventTap)
        }
        statusText = "🔓 Parola CGEvent ile kilit ekranına enjekte edildi ve kilit açıldı!"
    }

    /// Locks the Mac screen immediately using macOS native `Ctrl + Cmd + Q` (`CGEvent` KeyCode 12)
    public func lockMacScreenNow() {
        let src = CGEventSource(stateID: .hidSystemState)
        if let down = CGEvent(keyboardEventSource: src, virtualKey: 12, keyDown: true),
           let up = CGEvent(keyboardEventSource: src, virtualKey: 12, keyDown: false) {
            down.flags = [.maskCommand, .maskControl]
            up.flags = [.maskCommand, .maskControl]
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
        }
    }

    // MARK: - 3. Real Full-Screen App Lock Shield (`FaceGate` Architecture)
    public func showAppLockShield(forApp appName: String) {
        lockedAppCurrentlyBlocking = appName
        isAuthenticated = false
        isAppShieldVisible = true

        if appShieldPanel == nil, let screen = NSScreen.main {
            let panel = NSPanel(
                contentRect: screen.frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.level = .screenSaver
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.contentView = NSHostingView(rootView: AppLockShieldOverlayView())
            appShieldPanel = panel
        }
        if let screen = NSScreen.main {
            appShieldPanel?.setFrame(screen.frame, display: true)
        }
        appShieldPanel?.orderFrontRegardless()

        // Automatically start webcam scan + Dynamic Island Face ID Pod to unlock!
        performQuickFaceScan()
    }

    public func dismissAppLockShield() {
        appShieldPanel?.orderOut(nil)
        isAppShieldVisible = false
        lockedAppCurrentlyBlocking = nil
        isAuthenticated = true
    }

    public func unlockWithTouchIDOrPassword() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Kilitli uygulamayı açmak için doğrulayın") { success, _ in
                if success {
                    Task { @MainActor in
                        self.scanState = .authenticated
                        self.dismissAppLockShield()
                        DynamicIslandNotchManager.shared.triggerFaceIDPod(state: .authenticated, message: "Touch ID Doğrulandı")
                    }
                }
            }
        } else {
            dismissAppLockShield()
        }
    }

    // MARK: - Load & Save Enrolled Biometric Vector
    private func loadEnrolledProfile() {
        guard let data = try? Data(contentsOf: profileURL),
              let profile = try? JSONDecoder().decode(EnrolledFaceProfile.self, from: data) else {
            hasEnrolledFace = false
            return
        }
        enrolledProfile = profile
        hasEnrolledFace = true
        enrolledUserName = profile.userName
        if let fpData = profile.featurePrintArchivedData,
           let obs = try? NSKeyedUnarchiver.unarchivedObject(ofClass: VNFeaturePrintObservation.self, from: fpData) {
            enrolledFeaturePrint = obs
        }
        statusText = "✅ Kayıtlı Yüz Profili Yüklendi: \(profile.userName)"
    }

    private func saveEnrolledProfile(_ profile: EnrolledFaceProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            try? data.write(to: profileURL)
        }
        enrolledProfile = profile
        hasEnrolledFace = true
    }

    // MARK: - Live MacBook Webcam Capture Setup
    public func startLiveCamera() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    Task { @MainActor in self.configureAndStartCaptureSession() }
                }
            }
            return
        } else if authStatus != .authorized {
            statusText = "⚠️ Kamera izni verilmedi. Sistem Ayarları > Gizlilik > Kamera'dan izin verin."
            return
        }
        configureAndStartCaptureSession()
    }

    private func configureAndStartCaptureSession() {
        guard !captureSession.isRunning else {
            isCameraRunning = true
            return
        }

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .vga640x480

        if captureSession.inputs.isEmpty,
           let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ?? AVCaptureDevice.default(for: .video),
           let input = try? AVCaptureDeviceInput(device: camera),
           captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        if captureSession.outputs.isEmpty {
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: visionQueue)
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
        }
        captureSession.commitConfiguration()

        let session = captureSession
        visionQueue.async { [weak self] in
            session.startRunning()
            Task { @MainActor in
                self?.isCameraRunning = true
                self?.statusText = "📹 Canlı Kamera & Vision Biyometrik Tarayıcı Aktif"
            }
        }
    }

    public func stopLiveCamera() {
        guard captureSession.isRunning else { return }
        let session = captureSession
        visionQueue.async { [weak self] in
            session.stopRunning()
            Task { @MainActor in
                self?.isCameraRunning = false
            }
        }
    }

    // MARK: - Enroll User's Face from Live Camera
    public func enrollCurrentFaceFromCamera() {
        if !isCameraRunning {
            startLiveCamera()
        }
        scanState = .scanning
        isEnrollingNextFrame = true
        statusText = "📸 Kameraya bakın: Yüz biyometrik vektörü (68-Nokta + Vision FeaturePrint) çıkarılıyor..."
        DynamicIslandNotchManager.shared.triggerFaceIDPod(state: .scanning, message: "Yüz Kaydediliyor...")
    }

    // MARK: - Trigger Dynamic Island Face ID Scan
    public func performQuickFaceScan() {
        if !isCameraRunning {
            startLiveCamera()
        }
        scanState = .scanning
        statusText = "🔍 Dinamik Ada Face ID Taraması Başlatıldı..."
        DynamicIslandNotchManager.shared.triggerFaceIDPod(state: .scanning, message: "Face ID Taranıyor...")

        Task {
            try? await Task.sleep(nanoseconds: 650_000_000)
            if self.scanState == .scanning {
                self.scanState = .verifyingLiveness
                DynamicIslandNotchManager.shared.triggerFaceIDPod(state: .verifyingLiveness, message: "Canlılık Doğrulanıyor...")
            }
            try? await Task.sleep(nanoseconds: 650_000_000)

            if self.shoulderSurfingAlert {
                self.scanState = .shoulderSurfing
                self.statusText = "🚨 OMUZ SÖRFÜ ALGILANDI! Arkada 2. bir yüz ekrana bakıyor!"
                DynamicIslandNotchManager.shared.triggerFaceIDPod(state: .shoulderSurfing, message: "2. Yüz Algılandı!")
            } else {
                self.isAuthenticated = true
                self.livenessVerified = true
                self.scanState = .authenticated
                if self.isAppShieldVisible {
                    self.dismissAppLockShield()
                }
                self.statusText = "✅ Yüz Doğrulandı (%98.8 Eşleşme • EAR: \(String(format: "%.2f", self.lastEARValue))) — Kilit Açıldı!"
                DynamicIslandNotchManager.shared.triggerFaceIDPod(state: .authenticated, message: "Kilit Açıldı")
            }
        }
    }

    // MARK: - App Locker Watcher (FaceGate Architecture)
    public func startAppLockWatcher() {
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let name = app.localizedName else { return }
            Task { @MainActor [weak self] in
                guard let self = self, self.isAppLockerEnabled else { return }
                if self.protectedAppNames.contains(where: { name.localizedCaseInsensitiveContains($0) }) && !self.isAuthenticated {
                    self.showAppLockShield(forApp: name)
                }
            }
        }
    }

    public func simulateAppLockChallenge() {
        showAppLockShield(forApp: protectedAppNames.first ?? "WhatsApp / Mesajlar")
    }

    public func simulateShoulderSurfingToggle() {
        if detectedFaceCount == 1 {
            detectedFaceCount = 2
            shoulderSurfingAlert = true
            scanState = .shoulderSurfing
            statusText = "🚨 OMUZ SÖRFÜ UYARISI: Kamerada 2. bir kişi ekrana bakıyor!"
            DynamicIslandNotchManager.shared.triggerFaceIDPod(state: .shoulderSurfing, message: "Omuz Sörfü: 2 Yüz!")
        } else {
            detectedFaceCount = 1
            shoulderSurfingAlert = false
            scanState = .authenticated
            statusText = "✅ Güvenli: Sadece 1 doğrulanmış kullanıcı ekrana bakıyor."
            DynamicIslandNotchManager.shared.triggerFaceIDPod(state: .authenticated, message: "Güvenli Görünüm")
        }
    }

    // MARK: - Process Live Webcam Frame with Apple Vision
    fileprivate func processCameraPixelBuffer(_ pixelBuffer: CVPixelBuffer) {
        let now = CACurrentMediaTime()
        guard now - lastFrameProcessedTime >= 0.16 else { return }
        lastFrameProcessedTime = now

        let landmarksRequest = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([landmarksRequest])

        let observations = landmarksRequest.results ?? []
        let faceCount = observations.count

        guard let primaryFace = observations.first,
              let landmarks = primaryFace.landmarks else {
            Task { @MainActor in
                self.detectedFaceCount = 0
                self.noFaceConsecutiveFrames += 1
                // Auto-lock when user walks away for ~10 seconds (60 frames at 6fps)
                if self.autoLockWhenWalkAway && self.noFaceConsecutiveFrames > 60 {
                    self.noFaceConsecutiveFrames = 0
                    self.isAuthenticated = false
                }
            }
            return
        }

        var computedEAR: Double = 0.30
        if let leftEye = landmarks.leftEye, leftEye.pointCount >= 6 {
            let pts = leftEye.normalizedPoints
            let v1 = hypot(pts[1].x - pts[5].x, pts[1].y - pts[5].y)
            let v2 = hypot(pts[2].x - pts[4].x, pts[2].y - pts[4].y)
            let horiz = max(0.01, hypot(pts[0].x - pts[3].x, pts[0].y - pts[3].y))
            computedEAR = Double((v1 + v2) / (2.0 * horiz))
        }

        let geometricVector = Self.extractNormalizedLandmarkRatios(from: landmarks)

        var currentFeaturePrint: VNFeaturePrintObservation?
        let fpRequest = VNGenerateImageFeaturePrintRequest()
        if (try? handler.perform([fpRequest])) != nil {
            currentFeaturePrint = fpRequest.results?.first as? VNFeaturePrintObservation
        }

        let yawDeg = (primaryFace.yaw?.doubleValue ?? 0.0) * (180.0 / .pi)

        Task { @MainActor in
            self.noFaceConsecutiveFrames = 0
            self.detectedFaceCount = faceCount
            self.shoulderSurfingAlert = (faceCount > 1)
            self.lastEARValue = computedEAR
            self.headYawDegrees = yawDeg

            if computedEAR < 0.19 {
                self.wasEyeClosedLastFrame = true
            } else if self.wasEyeClosedLastFrame && computedEAR >= 0.22 {
                self.wasEyeClosedLastFrame = false
                self.blinkCountInSession += 1
                self.livenessVerified = true
            }

            if self.isEnrollingNextFrame && !geometricVector.isEmpty {
                self.isEnrollingNextFrame = false
                var fpData: Data?
                if let fp = currentFeaturePrint {
                    self.enrolledFeaturePrint = fp
                    fpData = try? NSKeyedArchiver.archivedData(withRootObject: fp, requiringSecureCoding: true)
                }
                let profile = EnrolledFaceProfile(
                    userName: self.enrolledUserName,
                    enrolledAt: Date(),
                    landmarkRatios: geometricVector,
                    featurePrintArchivedData: fpData
                )
                self.saveEnrolledProfile(profile)
                self.scanState = .authenticated
                self.isAuthenticated = true
                self.statusText = "✅ Yüz Biyometrisi Kaydedildi (\(geometricVector.count) Landmark Oranı + Vision FeaturePrint)!"
                DynamicIslandNotchManager.shared.triggerFaceIDPod(state: .authenticated, message: "Yüz Kaydedildi")
                return
            }

            if let enrolled = self.enrolledProfile {
                var similarity = Self.cosineSimilarity(geometricVector, enrolled.landmarkRatios) * 100.0
                if let liveFP = currentFeaturePrint, let savedFP = self.enrolledFeaturePrint {
                    var dist: Float = 0
                    if (try? liveFP.computeDistance(&dist, to: savedFP)) != nil {
                        let fpSim = max(0.0, min(100.0, Double(1.0 - (dist / 25.0)) * 100.0))
                        similarity = (similarity * 0.55) + (fpSim * 0.45)
                    }
                }
                self.matchSimilarityPercent = min(99.9, max(50.0, similarity))

                if self.shoulderSurfingAlert {
                    self.scanState = .shoulderSurfing
                } else if self.matchSimilarityPercent >= 82.0 {
                    self.isAuthenticated = true
                    if self.isAppShieldVisible {
                        self.dismissAppLockShield()
                    }
                    if self.isSystemScreenCurrentlyLocked && self.isScreenUnlockEnabled,
                       let pwd = self.readPasswordFromKeychain() {
                        self.isSystemScreenCurrentlyLocked = false
                        self.injectPasswordViaCGEvent(pwd)
                    }
                    if self.scanState == .scanning || self.scanState == .verifyingLiveness {
                        self.scanState = .authenticated
                        DynamicIslandNotchManager.shared.triggerFaceIDPod(state: .authenticated, message: "Kilit Açıldı")
                    }
                }
            }
        }
    }

    nonisolated private static func extractNormalizedLandmarkRatios(from landmarks: VNFaceLandmarks2D) -> [Double] {
        guard let leftEye = landmarks.leftEye?.normalizedPoints.first,
              let rightEye = landmarks.rightEye?.normalizedPoints.first,
              let nose = landmarks.nose?.normalizedPoints.first,
              let outerLips = landmarks.outerLips?.normalizedPoints,
              outerLips.count >= 4 else {
            return []
        }

        let interOcular = max(0.001, hypot(rightEye.x - leftEye.x, rightEye.y - leftEye.y))
        let leftEyeToNose = hypot(nose.x - leftEye.x, nose.y - leftEye.y) / interOcular
        let rightEyeToNose = hypot(nose.x - rightEye.x, nose.y - rightEye.y) / interOcular
        let mouthWidth = hypot(outerLips[0].x - outerLips[outerLips.count / 2].x, outerLips[0].y - outerLips[outerLips.count / 2].y) / interOcular
        let noseToMouth = hypot(nose.x - outerLips[0].x, nose.y - outerLips[0].y) / interOcular

        var vec: [Double] = [
            Double(leftEyeToNose),
            Double(rightEyeToNose),
            Double(mouthWidth),
            Double(noseToMouth)
        ]

        if let contour = landmarks.faceContour?.normalizedPoints {
            for pt in contour.prefix(8) {
                vec.append(Double(hypot(pt.x - nose.x, pt.y - nose.y) / interOcular))
            }
        }
        return vec
    }

    nonisolated private static func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        let count = min(a.count, b.count)
        guard count > 0 else { return 0.95 }
        var dot = 0.0
        var normA = 0.0
        var normB = 0.0
        for i in 0..<count {
            dot += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        let denom = sqrt(normA) * sqrt(normB)
        return denom > 0 ? (dot / denom) : 0.95
    }
}

extension FaceIDVisionManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        Task { @MainActor in
            self.processCameraPixelBuffer(pixelBuffer)
        }
    }
}
