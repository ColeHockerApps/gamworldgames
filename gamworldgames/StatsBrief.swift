//
//  StatsBrief.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import SwiftUI

struct StatsBrief: View {
    @EnvironmentObject private var theme: TorchTheme
    @EnvironmentObject private var storage: StorageBox

    @State private var range: Range = .month
    private let engine = SplitEngine()

    var body: some View {
        ZStack {
            Rectangle().fill(theme.arenaBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    header
                    rangePicker
                    overviewCard
                    categoryCard
                    peopleCard
                    sessionsCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            GlyphPack.tabStats(size: 26)
                .foregroundStyle(theme.accentColor)
            Text("Statistics")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
            Spacer()
        }
    }

    // MARK: - Range

    enum Range: String, CaseIterable, Identifiable {
        case week, month, all
        var id: String { rawValue }
        var title: String {
            switch self {
            case .week: return "7d"
            case .month: return "30d"
            case .all: return "All"
            }
        }
    }

    private var rangePicker: some View {
        HStack {
            Text("Range")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
            Spacer()
            Picker("", selection: $range) {
                ForEach(Range.allCases) { r in Text(r.title).tag(r) }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 240)
        }
        .padding(12)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Cards

    private var overviewCard: some View {
        let sessions = filteredSessions()
        let total = sessions.reduce(0) { $0 + $1.totalAmount }.roundedMoney()
        let avg = sessions.isEmpty ? 0 : (total / Decimal(sessions.count)).roundedMoney()

        return VStack(alignment: .leading, spacing: 10) {
            Text("Overview")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

            HStack {
                GlyphPack.coin(size: 22).foregroundStyle(theme.accentColor)
                Text("Total spent: \(MoneyUnits.shared.format(total))")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }

            HStack {
                GlyphPack.statsPerson(size: 20).foregroundStyle(theme.accentColor)
                Text("Sessions: \(sessions.count)")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text("Avg per session: \(MoneyUnits.shared.format(avg))")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(theme.textPrimary)
        }
        .padding(16)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: theme.shadow.color, radius: theme.shadow.radius, y: theme.shadow.y)
    }

    private var categoryCard: some View {
        let sessions = filteredSessions()
        var totals: [ExpenseCategory: Decimal] = [:]
        for s in sessions {
            let t = engine.totalsByCategory(for: s)
            for (k, v) in t { totals[k, default: 0] += v }
        }
        let ordered = ExpenseCategory.allCases
            .compactMap { cat -> (ExpenseCategory, Decimal)? in
                guard let v = totals[cat], v > 0 else { return nil }
                return (cat, v.roundedMoney())
            }
            .sorted { $0.1 > $1.1 }

        return VStack(alignment: .leading, spacing: 10) {
            Text("By Category")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

            if ordered.isEmpty {
                Text("No data for this range.")
                    .font(.footnote)
                    .foregroundStyle(theme.textSecondary)
            } else {
                ForEach(ordered, id: \.0) { (cat, amount) in
                    HStack(spacing: 10) {
                        categoryGlyph(cat)
                            .frame(width: 18, height: 18)
                            .foregroundStyle(colorForCategory(cat))
                        Text(cat.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)
                        Spacer()
                        Text(MoneyUnits.shared.format(amount))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(theme.textPrimary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var peopleCard: some View {
        let sessions = filteredSessions()
        let allPeople = Set(sessions.flatMap { $0.participants }).sorted { $0.name < $1.name }

        struct PersonAgg: Identifiable {
            let id: UUID
            let name: String
            var paid: Decimal = 0
            var owes: Decimal = 0
            var net: Decimal { (paid - owes).roundedMoney() }
            var matches: Int = 0
        }

        var map: [UUID: PersonAgg] = Dictionary(uniqueKeysWithValues: allPeople.map { ($0.id, PersonAgg(id: $0.id, name: $0.name)) })
        for s in sessions {
            for p in s.participants {
                var agg = map[p.id] ?? PersonAgg(id: p.id, name: p.name)
                let d = engine.detail(for: p, in: s)
                agg.paid += d.paid
                agg.owes += d.owes
                agg.matches += 1
                map[p.id] = agg
            }
        }

        let rows = map.values.sorted {
            if $0.net != $1.net { return $0.net > $1.net }
            return $0.paid > $1.paid
        }

        let topPayer = rows.max(by: { $0.paid < $1.paid })
        let mostActive = rows.max(by: { $0.matches < $1.matches })

        return VStack(alignment: .leading, spacing: 10) {
            Text("People")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

            if let payer = topPayer {
                HStack(spacing: 8) {
                    GlyphPack.statsCash(size: 18).foregroundStyle(theme.accentColor)
                    Text("Top payer: \(payer.name) • \(MoneyUnits.shared.format(payer.paid.roundedMoney()))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                }
            }

            if let active = mostActive {
                HStack(spacing: 8) {
                    GlyphPack.statsPerson(size: 18).foregroundStyle(theme.accentColor)
                    Text("Most active: \(active.name) • \(active.matches) sessions")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                }
            }

            Divider().background(theme.border)

            if rows.isEmpty {
                Text("No participant stats yet.")
                    .font(.footnote)
                    .foregroundStyle(theme.textSecondary)
            } else {
                ForEach(rows.prefix(6)) { row in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(theme.accentColor.opacity(0.18))
                            .overlay(Text(String(row.name.prefix(1))).font(.system(size: 13, weight: .bold)))
                            .frame(width: 26, height: 26)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(theme.textPrimary)
                            Text("Paid \(MoneyUnits.shared.format(row.paid.roundedMoney())) • Owes \(MoneyUnits.shared.format(row.owes.roundedMoney()))")
                                .font(.system(size: 11))
                                .foregroundStyle(theme.textSecondary)
                        }

                        Spacer()

                        Text(MoneyUnits.shared.format(row.net))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(row.net >= 0 ? ColorRack.teal : ColorRack.red)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var sessionsCard: some View {
        let sessions = filteredSessions()
        return VStack(alignment: .leading, spacing: 10) {
            Text("Sessions")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

            if sessions.isEmpty {
                Text("No sessions in this range.")
                    .font(.footnote)
                    .foregroundStyle(theme.textSecondary)
            } else {
                ForEach(sessions.prefix(5)) { s in
                    HStack(spacing: 10) {
                        GlyphPack.tabSessions(size: 18)
                            .foregroundStyle(theme.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(theme.textPrimary)
                            Text(s.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 11))
                                .foregroundStyle(theme.textSecondary)
                        }
                        Spacer()
                        Text(MoneyUnits.shared.format(s.totalAmount))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(theme.textPrimary)
                    }
                    .padding(10)
                    .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(16)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Helpers

    private func filteredSessions() -> [ExpenseSession] {
        let all = storage.sessions
        guard !all.isEmpty else { return [] }
        let now = Date()
        let cal = Calendar.current

        switch range {
        case .week:
            guard let start = cal.date(byAdding: .day, value: -7, to: now) else { return all }
            return all.filter { $0.date >= start }
        case .month:
            guard let start = cal.date(byAdding: .month, value: -1, to: now) else { return all }
            return all.filter { $0.date >= start }
        case .all:
            return all
        }
    }

    private func categoryGlyph(_ cat: ExpenseCategory) -> some View {
        switch cat {
        case .food:    return AnyView(GlyphPack.categoryFood())
        case .drinks:  return AnyView(GlyphPack.categoryDrinks())
        case .ride:    return AnyView(GlyphPack.categoryRide())
        case .tickets: return AnyView(GlyphPack.categoryTickets())
        case .merch:   return AnyView(GlyphPack.categoryMerch())
        case .other:   return AnyView(GlyphPack.categoryOther())
        }
    }

    private func colorForCategory(_ cat: ExpenseCategory) -> Color {
        switch cat {
        case .food: return ColorRack.categoryFood
        case .drinks: return ColorRack.categoryDrinks
        case .ride: return ColorRack.categoryRide
        case .tickets: return ColorRack.categoryTickets
        case .merch: return ColorRack.categoryMerch
        case .other: return theme.accentColor
        }
    }
}
