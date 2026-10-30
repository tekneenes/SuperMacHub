import Foundation
import AppKit
import ApplicationServices

@MainActor
public final class MouseFixManager: ObservableObject {
    public static let shared = MouseFixManager()

    @Published public var isEnabled: Bool = false
    @Published public var invertExternalMouseScroll: Bool = true
    @Published public var smoothScrollMultiplier: Double = 1.35
    @Published public var disablePointerAcceleration: Bool = false
    @Published public var sideButton4Action: String = "Mission Control"
    @Published public var sideButton5Action: String = "Eney AI Wand (⌥+W)"
    @Published public var totalInterceptedScrollEvents: Int = 0
    @Published public var statusText: String = "Hazır (Trackpad doğal kaydırmayı bozmadan harici mouse düzeltici)"

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    public let availableButtonActions = [
        "Mission Control",
        "Eney AI Wand (⌥+W)",
        "Masaüstünü Göster",
        "Uygulama Pencereleri (Exposé)",
        "Pencereyi Sola Yasla",
        "Pencereyi Sağa Yasla"
    ]

    private init() {}

    public func startMouseFix() {
        guard AXIsProcessTrusted() else {
            PermissionsManager.shared.requestAccessibility()
            statusText = "⚠️ CGEventTap için Accessibility (Erişilebilirlik) izni gerekiyor."
            return
        }
        guard eventTap == nil else { return }

        let mask = (1 << CGEventType.scrollWheel.rawValue) | (1 << CGEventType.otherMouseDown.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, userInfo in
                guard let userInfo = userInfo else { return Unmanaged.passUnretained(event) }
                let manager = Unmanaged<MouseFixManager>.fromOpaque(userInfo).takeUnretainedValue()

                if type == .scrollWheel {
                    // Continuous == 0 means physical mouse wheel (non-Trackpad!)
                    let isTrackpad = event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0
                    if !isTrackpad {
                        let deltaY = event.getDoubleValueField(.scrollWheelEventDeltaAxis1)
                        let sign: Double = manager.invertExternalMouseScroll ? -1.0 : 1.0
                        let adjusted = Int64((deltaY * sign * manager.smoothScrollMultiplier).rounded())
                        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: adjusted)
                        Task { @MainActor in
                            manager.totalInterceptedScrollEvents += 1
                        }
                    }
                } else if type == .otherMouseDown {
                    let buttonNumber = event.getIntegerValueField(.mouseEventButtonNumber)
                    if buttonNumber == 3 {
                        Task { @MainActor in
                            manager.triggerButtonAction(manager.sideButton4Action)
                        }
                    } else if buttonNumber == 4 {
                        Task { @MainActor in
                            manager.triggerButtonAction(manager.sideButton5Action)
                        }
                    }
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: refcon
        ) else {
            statusText = "⚠️ Mouse EventTap başlatılamadı."
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.eventTap = tap
        self.runLoopSource = source
        self.isEnabled = true
        self.statusText = "✅ Aktif: Harici mouse kaydırma yönü & yan tuşlar dinleniyor."
    }

    public func stopMouseFix() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), src, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        isEnabled = false
        statusText = "Durduruldu (0 CPU tüketimi)."
    }

    public func triggerButtonAction(_ action: String) {
        switch action {
        case "Mission Control":
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Mission Control.app"))
        case "Eney AI Wand (⌥+W)":
            EneyAIAgentManager.shared.toggleWandFloatingPanel()
        case "Pencereyi Sola Yasla":
            WindowLoopManager.shared.snapFocusedWindow(to: .leftHalf)
        case "Pencereyi Sağa Yasla":
            WindowLoopManager.shared.snapFocusedWindow(to: .rightHalf)
        default:
            break
        }
    }
}
