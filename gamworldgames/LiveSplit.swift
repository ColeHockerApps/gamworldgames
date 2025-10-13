//
//  LiveSplit.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import SwiftUI

struct LiveSplit: View {
    @EnvironmentObject private var theme: TorchTheme
    @EnvironmentObject private var storage: StorageBox
    @EnvironmentObject private var haptics: HapticsWhistle

    // Working "live" session (in-memory until saved)
    @State private var session: ExpenseSession
    @State private var engine = SplitEngine()

    // Quick add inputs
    @State private var titleText: String = ""
    @State private var amountText: String = ""
    @State private var category: ExpenseCategory = .food
    @State private var payerId: UUID?
    @State private var consumers: Set<UUID> = []
    @State private var method: Method = .equal
    @State private var weights: [UUID: String] = [:]
    @State private var exacts: [UUID: String] = [:]

    // Save
    @State private var saveTitle: String = "Live Hangout"

    // MARK: - Init

    init() {
        let people = PeopleHub.shared.allPeople()
        var s = ExpenseSession(
            title: "Live Hangout",
            currencyCode: MoneyUnits.shared.selected.code,
            participants: people
        )
        _session = State(initialValue: s)
        _payerId = State(initialValue: people.first?.id)
        _consumers = State(initialValue: Set(people.map { $0.id }))
    }

    var body: some View {
        ZStack {
            Rectangle().fill(theme.arenaBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    quickAddCard
                    itemsCard
                    balancesCard
                    totalsCard
                    saveCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .onAppear {
            // Sync currency if user changed it in Settings
            session.currencyCode = MoneyUnits.shared.selected.code
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                GlyphPack.coin(size: 24)
                    .foregroundStyle(theme.accentColor)
                Text(session.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                Text(MoneyUnits.shared.format(session.totalAmount))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.accentColor)
            }

            Text("\(session.participants.count) people • \(session.items.count) items")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.textSecondary)
        }
        .padding(16)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: theme.shadow.color, radius: theme.shadow.radius, y: theme.shadow.y)
    }

    // MARK: - Quick Add

    private var quickAddCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Add")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

            VStack(spacing: 10) {
                TextField("Title (e.g., Pizza)", text: $titleText)
                    .textInputAutocapitalization(.words)
                    .padding(10)
                    .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                HStack {
                    Text(MoneyUnits.shared.selected.symbol)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(theme.textSecondary)
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                .padding(10)
                .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                // Category + Payer
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Category").font(.subheadline).foregroundStyle(theme.textSecondary)
                        Picker("", selection: $category) {
                            ForEach(ExpenseCategory.allCases, id: \.self) { c in
                                Text(c.title).tag(c)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(10)
                        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Payer").font(.subheadline).foregroundStyle(theme.textSecondary)
                        Picker("", selection: Binding(
                            get: { payerId ?? session.participants.first?.id },
                            set: { payerId = $0 })
                        ) {
                            ForEach(session.participants, id: \.id) { p in
                                Text(p.name).tag(p.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(10)
                        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }

                // Consumers
                VStack(alignment: .leading, spacing: 6) {
                    Text("Consumers").font(.subheadline).foregroundStyle(theme.textSecondary)
                    VStack(spacing: 8) {
                        ForEach(session.participants, id: \.id) { p in
                            Toggle(p.name, isOn: Binding(
                                get: { consumers.contains(p.id) },
                                set: { on in
                                    if on { consumers.insert(p.id) } else { consumers.remove(p.id) }
                                })
                            )
                            .tint(theme.accentColor)
                        }
                    }
                    .padding(10)
                    .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                // Split method
                VStack(alignment: .leading, spacing: 8) {
                    Text("Split").font(.subheadline).foregroundStyle(theme.textSecondary)
                    Picker("", selection: $method) {
                        Text("Equal").tag(Method.equal)
                        Text("Weights").tag(Method.weights)
                        Text("Exact").tag(Method.exact)
                    }
                    .pickerStyle(.segmented)

                    if method == .weights {
                        weightsEditor
                    } else if method == .exact {
                        exactsEditor
                    } else {
                        Text("Even split among selected consumers.")
                            .font(.footnote)
                            .foregroundStyle(theme.textSecondary)
                    }
                }

                HStack {
                    Button {
                        if addItem() {
                            haptics.success()
                        } else {
                            haptics.error()
                        }
                    } label: {
                        Label("Add Item", systemImage: "plus.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(
                                Capsule().fill(
                                    LinearGradient(colors: [theme.accentColor.opacity(0.25),
                                                            theme.accentColor.opacity(0.08)],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        clearInputs(keepPayerAndConsumers: true)
                        haptics.selection()
                    } label: {
                        Label("Clear", systemImage: "xmark.circle.fill")
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: theme.shadow.color, radius: theme.shadow.radius, y: theme.shadow.y)
    }

    private var weightsEditor: some View {
        let selected = session.participants.filter { consumers.contains($0.id) }
        return VStack(alignment: .leading, spacing: 6) {
            Text("Relative weights (e.g., 1, 2, 1.5)")
                .font(.footnote).foregroundStyle(theme.textSecondary)
            ForEach(selected, id: \.id) { p in
                HStack {
                    Text(p.name)
                    Spacer()
                    TextField("1", text: Binding(
                        get: { weights[p.id] ?? "" },
                        set: { weights[p.id] = $0 }
                    ))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var exactsEditor: some View {
        let selected = session.participants.filter { consumers.contains($0.id) }
        let sym = MoneyUnits.shared.selected.symbol
        let total = totalExactEntered
        return VStack(alignment: .leading, spacing: 6) {
            Text("Exact amounts (\(sym))")
                .font(.footnote).foregroundStyle(theme.textSecondary)
            ForEach(selected, id: \.id) { p in
                HStack {
                    Text(p.name)
                    Spacer()
                    TextField("0.00", text: Binding(
                        get: { exacts[p.id] ?? "" },
                        set: { exacts[p.id] = $0 }
                    ))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                }
                .padding(.vertical, 2)
            }
            if total > 0 {
                HStack {
                    Text("Entered total")
                    Spacer()
                    Text(MoneyUnits.shared.format(total))
                        .fontWeight(.semibold)
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Items list

    private var itemsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Items")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

            if session.items.isEmpty {
                Text("No items yet. Use Quick Add above.")
                    .font(.footnote)
                    .foregroundStyle(theme.textSecondary)
            } else {
                ForEach(session.items) { item in
                    HStack(spacing: 10) {
                        categoryGlyph(item.category)
                            .frame(width: 20, height: 20)
                            .foregroundStyle(colorForCategory(item.category))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(theme.textPrimary)
                            Text("\(payerName(for: item)) • \(item.consumerIds.count) consumers")
                                .font(.system(size: 11))
                                .foregroundStyle(theme.textSecondary)
                        }

                        Spacer()

                        Text(MoneyUnits.shared.format(item.amount))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(theme.textPrimary)
                    }
                    .padding(10)
                    .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button {
                    session.items.removeAll()
                    haptics.warning()
                } label: {
                    Label("Clear Items", systemImage: "trash")
                        .foregroundStyle(ColorRack.red)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Balances & Totals

    private var balancesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Balances")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

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
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var totalsCard: some View {
        let totals = engine.totalsByCategory(for: session)
        let ordered = ExpenseCategory.allCases.filter { totals[$0] != nil }
        return VStack(alignment: .leading, spacing: 10) {
            Text("Totals by Category")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)
            if ordered.isEmpty {
                Text("No totals yet.")
                    .font(.footnote)
                    .foregroundStyle(theme.textSecondary)
            } else {
                ForEach(ordered, id: \.self) { cat in
                    let amount = totals[cat] ?? 0
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
                }
            }
        }
        .padding(16)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Save

    private var saveCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Save as Session")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

            TextField("Title", text: $saveTitle)
                .textInputAutocapitalization(.words)
                .padding(10)
                .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack {
                Button {
                    saveSession()
                } label: {
                    Label("Save", systemImage: "tray.and.arrow.down.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(
                            Capsule().fill(
                                LinearGradient(colors: [theme.accentColor.opacity(0.25),
                                                        theme.accentColor.opacity(0.08)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                        )
                }
                .buttonStyle(.plain)
                .disabled(session.items.isEmpty)

                Spacer()

                Button {
                    session.items.removeAll()
                    titleText = ""
                    amountText = ""
                    weights.removeAll()
                    exacts.removeAll()
                    haptics.selection()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise.circle.fill")
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Logic

    private func addItem() -> Bool {
        guard let pid = payerId,
              let payer = session.participants.first(where: { $0.id == pid }) else { return false }

        let amount = MoneyUnits.shared.parse(amountText)
        guard amount > 0 else { return false }

        let selected = session.participants.filter { consumers.contains($0.id) }
        guard !selected.isEmpty else { return false }

        let splitMethod: SplitMethod
        switch method {
        case .equal:
            splitMethod = .equal
        case .weights:
            var map: [UUID: Decimal] = [:]
            for c in selected {
                let raw = (weights[c.id] ?? "").replacingOccurrences(of: ",", with: ".")
                if let v = Decimal(string: raw), v > 0 { map[c.id] = v }
            }
            splitMethod = .weights(map)
        case .exact:
            var map: [UUID: Decimal] = [:]
            for c in selected {
                let raw = (exacts[c.id] ?? "").replacingOccurrences(of: ",", with: ".")
                if let v = Decimal(string: raw), v >= 0 { map[c.id] = v }
            }
            splitMethod = .exact(map)
        }

        do {
            let item = try engine.buildLineItem(
                title: titleText.trimmingCharacters(in: .whitespacesAndNewlines),
                total: amount,
                category: category,
                payer: payer,
                consumers: selected,
                method: splitMethod
            )
            session.items.insert(item, at: 0)
            clearInputs(keepPayerAndConsumers: true)
            return true
        } catch {
            return false
        }
    }

    private func clearInputs(keepPayerAndConsumers: Bool) {
        let keepPid = payerId
        let keepConsumers = consumers
        titleText = ""
        amountText = ""
        category = .food
        method = .equal
        weights.removeAll()
        exacts.removeAll()
        if keepPayerAndConsumers {
            payerId = keepPid
            consumers = keepConsumers
        } else {
            payerId = session.participants.first?.id
            consumers = Set(session.participants.map { $0.id })
        }
    }

    private func saveSession() {
        var new = ExpenseSession(
            title: saveTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Live Hangout" : saveTitle,
            currencyCode: session.currencyCode,
            participants: session.participants
        )
        new.items = session.items
        new.date = Date()
        storage.addSession(new)
        haptics.success()
    }

    // MARK: - Helpers

    private var totalExactEntered: Decimal {
        var sum: Decimal = 0
        for id in consumers {
            if let txt = exacts[id] {
                let v = Decimal(string: txt.replacingOccurrences(of: ",", with: ".")) ?? 0
                sum += v
            }
        }
        return sum.roundedMoney()
    }

    private func payerName(for item: LineItem) -> String {
        session.participants.first(where: { $0.id == item.payerId })?.name ?? "Payer"
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

    enum Method: String, Hashable { case equal, weights, exact }
}
