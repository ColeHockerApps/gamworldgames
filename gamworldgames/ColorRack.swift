//
//  ColorRack.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import SwiftUI
import Combine


enum ColorRack {
    // MARK: - Accents
    static let blue = Color(hex: "#4A90E2")
    static let mint = Color(hex: "#4CD2B1")
    static let violet = Color(hex: "#B27CF5")
    static let orange = Color(hex: "#F5A623")
    static let red = Color(hex: "#E94E77")
    static let gold = Color(hex: "#F7C948")
    static let teal = Color(hex: "#3EC6C0")

    // MARK: - Surfaces
    static let surfaceDark = Color(hex: "#111214")
    static let surfaceDarkElevated = Color(hex: "#1B1C1F")
    static let surfaceLight = Color(hex: "#F3F4F6")
    static let surfaceLightElevated = Color(hex: "#FFFFFF")

    // MARK: - Text
    static let textOnDark = Color.white
    static let textOnDarkSecondary = Color.white.opacity(0.65)
    static let textOnLight = Color.black
    static let textOnLightSecondary = Color.black.opacity(0.7)

    // MARK: - Borders
    static let borderDark = Color.white.opacity(0.08)
    static let borderLight = Color.black.opacity(0.1)

    // MARK: - Categories
    static let categoryFood = Color(hex: "#F6A700")
    static let categoryDrinks = Color(hex: "#29ABE2")
    static let categoryRide = Color(hex: "#7ED321")
    static let categoryTickets = Color(hex: "#9013FE")
    static let categoryMerch = Color(hex: "#D0021B")
}

// MARK: - Color Hex initializer

extension Color {
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: 1.0
        )
    }
}
