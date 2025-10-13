//
//  HomeBoard.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import SwiftUI

struct HomeBoard: View {
    @EnvironmentObject private var theme: TorchTheme
    @EnvironmentObject private var storage: StorageBox
    @EnvironmentObject private var haptics: HapticsWhistle

    var body: some View {
        ZStack {
            Rectangle()
                .fill(theme.arenaBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header
                    summaryCard
                    recentSessions
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 10) {
            GlyphPack.statsTrophy(size: 28)
                .foregroundStyle(theme.accentColor)
            Text("GamWorld Games")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
            Spacer()
        }
    }

    // MARK: - Summary Card
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

            let totalSpent = storage.sessions.reduce(Decimal(0)) { $0 + $1.totalAmount }
            let formatted = MoneyUnits.shared.format(totalSpent)

            HStack {
                GlyphPack.coin(size: 24)
                    .foregroundStyle(theme.accentColor)
                Text("Total spent: \(formatted)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: theme.shadow.color, radius: theme.shadow.radius, y: theme.shadow.y)
    }

    // MARK: - Recent Sessions
    private var recentSessions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Sessions")
                    .font(.headline)
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                NavigationLink(destination: SessionList()) {
                    Text("View All")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.accentColor)
                }
            }

            if storage.sessions.isEmpty {
                Text("No sessions yet. Start by adding a new one!")
                    .font(.footnote)
                    .foregroundStyle(theme.textSecondary)
                    .padding(.top, 4)
            } else {
                ForEach(storage.sessions.prefix(3)) { session in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(session.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(theme.textPrimary)
                            Spacer()
                            Text(MoneyUnits.shared.format(session.totalAmount))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(theme.accentColor)
                        }
                        Text(session.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 12))
                            .foregroundStyle(theme.textSecondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: theme.shadow.color.opacity(0.3), radius: theme.shadow.radius / 2, y: 1)
                }
            }

            NavigationLink(destination: SessionEditor(onSave: { session in
                storage.addSession(session)
                haptics.success()
            })) {
                Label("Add New Session", systemImage: "plus.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(GradientCapsule(start: theme.accentColor.opacity(0.25), end: theme.accentColor.opacity(0.1)))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Capsule Gradient

struct GradientCapsule: View {
    var start: Color
    var end: Color
    var body: some View {
        Capsule()
            .fill(LinearGradient(colors: [start, end], startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}
