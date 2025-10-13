//
//  TorchTheme.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import SwiftUI
import Combine

final class TorchTheme: ObservableObject {
   
    @Published var isDark: Bool = true
    @Published var accentColor: Color = ColorRack.blue
    @Published var cardBackground: Color = ColorRack.surfaceDarkElevated
    @Published var arenaBackground: Color = ColorRack.surfaceDark
    @Published var textPrimary: Color = ColorRack.textOnDark
    @Published var textSecondary: Color = ColorRack.textOnDarkSecondary
    @Published var border: Color = ColorRack.borderDark
    @Published var shadow: ShadowPack = .softDark

    // MARK: - Modes

    func applyDarkMode() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isDark = true
            cardBackground = ColorRack.surfaceDarkElevated
            arenaBackground = ColorRack.surfaceDark
            textPrimary = ColorRack.textOnDark
            textSecondary = ColorRack.textOnDarkSecondary
            border = ColorRack.borderDark
            shadow = .softDark
        }
    }

    func applyLightMode() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isDark = false
            cardBackground = ColorRack.surfaceLightElevated
            arenaBackground = ColorRack.surfaceLight
            textPrimary = ColorRack.textOnLight
            textSecondary = ColorRack.textOnLightSecondary
            border = ColorRack.borderLight
            shadow = .softLight
        }
    }

    // MARK: - Accent

    func setAccent(_ accent: Accent) {
        withAnimation(.easeInOut(duration: 0.25)) {
            accentColor = accent.color
        }
    }

    enum Accent: String, CaseIterable, Identifiable {
        case blue, mint, violet, orange, red, gold, teal
        var id: String { rawValue }
        var color: Color {
            switch self {
            case .blue: return ColorRack.blue
            case .mint: return ColorRack.mint
            case .violet: return ColorRack.violet
            case .orange: return ColorRack.orange
            case .red: return ColorRack.red
            case .gold: return ColorRack.gold
            case .teal: return ColorRack.teal
            }
        }
    }

    // MARK: - Shadow presets

    struct ShadowPack {
        let color: Color
        let radius: CGFloat
        let y: CGFloat

        static let softDark = ShadowPack(color: .black.opacity(0.3), radius: 6, y: 3)
        static let softLight = ShadowPack(color: .gray.opacity(0.2), radius: 4, y: 2)
    }
}
