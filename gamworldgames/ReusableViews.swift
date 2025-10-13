//
//  ReusableViews.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import SwiftUI

// MARK: - PressableStyle
/// Subtle scale + opacity feedback for buttons.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    var pressedOpacity: CGFloat = 0.85

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? pressedOpacity : 1)
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: configuration.isPressed)
    }
}

// MARK: - SoftDivider
/// Thin divider that adapts to the current theme.
struct SoftDivider: View {
    @EnvironmentObject private var theme: TorchTheme
    var body: some View {
        Rectangle()
            .fill(theme.border)
            .frame(height: 1)
            .cornerRadius(0.5)
    }
}

// MARK: - SectionHeader
/// Consistent small section header used across screens.
struct SectionHeader: View {
    @EnvironmentObject private var theme: TorchTheme
    var title: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let sf = systemImage {
                Image(systemName: sf)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(theme.accentColor)
            }
            Text(title.uppercased())
                .font(.system(size: 12, weight: .black))
                .kerning(0.6)
                .foregroundStyle(theme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 2)
    }
}

// MARK: - KeyValueRow
/// Title on the left, value on the right.
struct KeyValueRow: View {
    @EnvironmentObject private var theme: TorchTheme
    var title: String
    var value: String
    var accent: Color? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(accent ?? theme.textPrimary)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - InfoBanner
/// Rounded info banner for hints and lightweight alerts.
struct InfoBanner: View {
    @EnvironmentObject private var theme: TorchTheme
    var text: String
    var systemImage: String = "info.circle.fill"

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(theme.accentColor)
                .padding(.top, 2)

            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(theme.border, lineWidth: 1)
        )
    }
}

// MARK: - MoneyText
/// Displays a Decimal formatted in the currently selected currency.
struct MoneyText: View {
    var amount: Decimal
    var weight: Font.Weight = .bold
    var size: CGFloat = 14

    var body: some View {
        Text(MoneyUnits.shared.format(amount))
            .font(.system(size: size, weight: weight))
    }
}
