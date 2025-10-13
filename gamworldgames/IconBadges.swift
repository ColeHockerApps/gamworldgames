//
//  IconBadges.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import SwiftUI

// MARK: - RibbonBadge
// Compact pill with text; used for ranks, short labels, currency tags.

struct RibbonBadge: View {
    var text: String
    var color: Color

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .black, design: .rounded))
            .kerning(0.5)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(color.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.35), lineWidth: 1)
            )
            .foregroundStyle(color)
    }
}

// MARK: - ScorePill
// Number emphasized in a soft capsule.

struct ScorePill: View {
    var title: String
    var value: String
    var tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint.opacity(0.85))
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(tint.opacity(0.12))
        )
        .overlay(
            Capsule().stroke(tint.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - CategoryBadge
// Icon + title for ExpenseCategory

struct CategoryBadge: View {
    @EnvironmentObject private var theme: TorchTheme
    var category: ExpenseCategory

    var body: some View {
        HStack(spacing: 8) {
            icon
                .frame(width: 16, height: 16)
                .foregroundStyle(color.opacity(0.95))
            Text(category.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(color.opacity(0.12))
        )
        .overlay(
            Capsule().stroke(color.opacity(0.25), lineWidth: 1)
        )
    }

    private var icon: some View {
        switch category {
        case .food:    return AnyView(GlyphPack.categoryFood(size: 16))
        case .drinks:  return AnyView(GlyphPack.categoryDrinks(size: 16))
        case .ride:    return AnyView(GlyphPack.categoryRide(size: 16))
        case .tickets: return AnyView(GlyphPack.categoryTickets(size: 16))
        case .merch:   return AnyView(GlyphPack.categoryMerch(size: 16))
        case .other:   return AnyView(GlyphPack.categoryOther(size: 16))
        }
    }

    private var color: Color {
        switch category {
        case .food: return ColorRack.categoryFood
        case .drinks: return ColorRack.categoryDrinks
        case .ride: return ColorRack.categoryRide
        case .tickets: return ColorRack.categoryTickets
        case .merch: return ColorRack.categoryMerch
        case .other: return theme.accentColor
        }
    }
}

// MARK: - StatBadge
// Generic icon + value badge (e.g., "Items 12")

struct StatBadge: View {
    @EnvironmentObject private var theme: TorchTheme
    var systemImage: String
    var text: String
    var tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 16, height: 16)
                .foregroundStyle(tint)
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(tint.opacity(0.12))
        )
        .overlay(
            Capsule().stroke(tint.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - AvatarBadge
// Circle with initials, used in lists and balances.

struct AvatarBadge: View {
    var name: String
    var tint: Color = ColorRack.teal

    private var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }

    var body: some View {
        Circle()
            .fill(tint.opacity(0.18))
            .overlay(
                Text(initials.isEmpty ? "?" : initials)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(tint)
            )
            .frame(width: 26, height: 26)
    }
}
