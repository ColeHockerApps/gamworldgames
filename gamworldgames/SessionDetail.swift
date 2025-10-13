//
//  SessionDetail.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import SwiftUI

struct SessionDetail: View {
    @EnvironmentObject private var theme: TorchTheme
    @EnvironmentObject private var storage: StorageBox
    @EnvironmentObject private var haptics: HapticsWhistle

    // We keep a working copy to allow inline edits
    @State private var session: ExpenseSession
    @State private var showAdd = false
    @State private var editingItem: LineItem?

    private let engine = SplitEngine()

    init(session: ExpenseSession) {
        _session = State(initialValue: session)
    }

    var body: some View {
        ZStack {
            Rectangle().fill(theme.arenaBackground).ignoresSafeArea()

            List {
                // Header
                Section {
                    headerCard
                } header: {
                    Text("Session")
                }

                // Items
                Section {
                    if session.items.isEmpty {
                        Text("No expenses yet. Add the first one below.")
                            .font(.footnote)
                            .foregroundStyle(theme.textSecondary)
                            .listRowBackground(theme.cardBackground.opacity(0.6))
                    } else {
                        ForEach(session.items) { item in
                            itemRow(item)
                                .listRowBackground(theme.cardBackground)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        delete(item)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button {
                                        editingItem = item
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(theme.accentColor)
                                }
                        }
                    }
                } header: {
                    Text("Expenses")
                }

                // Balances
                Section {
                    balancesCard
                        .listRowBackground(theme.cardBackground)
                } header: {
                    Text("Balances")
                }

                // Totals by category
                Section {
                    totalsByCategoryCard
                        .listRowBackground(theme.cardBackground)
                } header: {
                    Text("Totals by Category")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAdd = true
                    haptics.selection()
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                }
            }
        }
        .onDisappear { persist() }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                EntryComposer(
                    participants: session.participants,
                    payerPrefill: session.participants.first
                ) { newItem in
                    session.items.insert(newItem, at: 0)
                    persist()
                }
                .environmentObject(theme)
                .environmentObject(haptics)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $editingItem) { item in
            NavigationStack {
                EntryComposer(
                    participants: session.participants,
                    payerPrefill: session.participants.first(where: { $0.id == item.payerId }),
                    editingItem: item
                ) { updated in
                    if let idx = session.items.firstIndex(where: { $0.id == updated.id }) {
                        session.items[idx] = updated
                        persist()
                    }
                }
                .environmentObject(theme)
                .environmentObject(haptics)
            }
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Cards

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                GlyphPack.tabSessions(size: 22)
                    .foregroundStyle(theme.accentColor)
                Text(session.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                Text(MoneyUnits.shared.format(session.totalAmount))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.accentColor)
            }
            Text(session.date.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.textSecondary)
            Text("\(session.participants.count) people • \(session.items.count) items")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.textSecondary)
        }
        .padding(.vertical, 6)
    }

    private func itemRow(_ item: LineItem) -> some View {
        HStack(spacing: 12) {
            categoryGlyph(item.category)
                .frame(width: 22, height: 22)
                .foregroundStyle(colorForCategory(item.category).opacity(0.9))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                Text("\(payerName(for: item)) • \(consumerCount(for: item))")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()

            Text(MoneyUnits.shared.format(item.amount))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(theme.textPrimary)
        }
        .padding(.vertical, 6)
    }

    private var balancesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(session.participants, id: \.id) { p in
                let d = engine.detail(for: p, in: session)
                HStack(spacing: 10) {
                    Circle()
                        .fill(theme.accentColor.opacity(0.18))
                        .overlay(Text(String(p.name.prefix(1))).font(.system(size: 13, weight: .bold)))
                        .frame(width: 26, height: 26)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)
                        Text("Paid \(MoneyUnits.shared.format(d.paid)) • Owes \(MoneyUnits.shared.format(d.owes))")
                            .font(.system(size: 11))
                            .foregroundStyle(theme.textSecondary)
                    }

                    Spacer()

                    Text(MoneyUnits.shared.format(d.net))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(d.net >= 0 ? ColorRack.teal : ColorRack.red)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var totalsByCategoryCard: some View {
        let totals = engine.totalsByCategory(for: session)
        let ordered = ExpenseCategory.allCases.filter { totals[$0] != nil }
        return VStack(spacing: 8) {
            if ordered.isEmpty {
                Text("No category totals yet.")
                    .font(.footnote)
                    .foregroundStyle(theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(ordered, id: \.self) { cat in
                    let amount = totals[cat] ?? 0
                    HStack(spacing: 10) {
                        categoryGlyph(cat)
                            .frame(width: 20, height: 20)
                            .foregroundStyle(colorForCategory(cat).opacity(0.9))

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
    }

    // MARK: - Actions

    private func delete(_ item: LineItem) {
        session.items.removeAll { $0.id == item.id }
        persist()
        haptics.warning()
    }

    private func persist() {
        storage.updateSession(session)
    }

    // MARK: - Helpers

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

    private func payerName(for item: LineItem) -> String {
        session.participants.first(where: { $0.id == item.payerId })?.name ?? "Payer"
    }

    private func consumerCount(for item: LineItem) -> String {
        let count = item.consumerIds.count
        return count == 1 ? "1 consumer" : "\(count) consumers"
    }
}
