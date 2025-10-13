//
//  HapticsWhistle.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import SwiftUI
import CoreHaptics
import Combine

final class HapticsWhistle: ObservableObject {
    private var engine: CHHapticEngine?
    private(set) var isAvailable: Bool = false
    @Published var isEnabled: Bool = true

    init() {
        prepareEngine()
    }

    // MARK: - Setup

    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            isAvailable = false
            return
        }

        do {
            engine = try CHHapticEngine()
            try engine?.start()
            isAvailable = true
        } catch {
            isAvailable = false
        }
    }

    func warmup() {
        if engine == nil { prepareEngine() }
    }

    // MARK: - Feedbacks

    func selection() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    func success() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func warning() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    func error() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    func light() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func medium() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func heavy() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    func goal() {
        playPattern(intensity: 0.7, sharpness: 0.8, duration: 0.2)
    }

    // MARK: - Custom patterns

    private func playPattern(intensity: Float, sharpness: Float, duration: TimeInterval) {
        guard isEnabled, isAvailable else { return }

        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            return
        }
    }
}
