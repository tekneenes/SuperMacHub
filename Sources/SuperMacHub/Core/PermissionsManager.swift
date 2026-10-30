import Foundation
import AppKit
import AVFoundation
import EventKit
import Speech

@MainActor
public final class PermissionsManager: ObservableObject {
    public static let shared = PermissionsManager()

    @Published public var isAccessibilityGranted: Bool = false
    @Published public var isScreenRecordingGranted: Bool = false
    @Published public var isCameraGranted: Bool = false
    @Published public var isMicrophoneGranted: Bool = false
    @Published public var isCalendarGranted: Bool = false
    @Published public var isSpeechGranted: Bool = false

    private let eventStore = EKEventStore()

    private init() {
        refreshAllPermissions()
    }

    public func refreshAllPermissions() {
        isAccessibilityGranted = AXIsProcessTrusted()
        isScreenRecordingGranted = CGPreflightScreenCaptureAccess()
        isCameraGranted = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        isMicrophoneGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized

        let calStatus = EKEventStore.authorizationStatus(for: .event)
        isCalendarGranted = (calStatus == .fullAccess)
        isSpeechGranted = SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    public func requestAccessibility() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        isAccessibilityGranted = AXIsProcessTrustedWithOptions(options)
    }

    public func requestScreenRecording() {
        isScreenRecordingGranted = CGRequestScreenCaptureAccess()
    }

    public func requestCamera() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            Task { @MainActor in
                self.isCameraGranted = granted
            }
        }
    }

    public func requestMicrophoneAndSpeech() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            Task { @MainActor in
                self.isMicrophoneGranted = granted
            }
        }
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                self.isSpeechGranted = (status == .authorized)
            }
        }
    }

    public func requestCalendarAndReminders() {
        eventStore.requestFullAccessToEvents { granted, _ in
            Task { @MainActor in
                self.isCalendarGranted = granted
            }
        }
        eventStore.requestFullAccessToReminders { _, _ in }
    }

    public func openSystemSettings(pane: String) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") {
            NSWorkspace.shared.open(url)
        }
    }
}
