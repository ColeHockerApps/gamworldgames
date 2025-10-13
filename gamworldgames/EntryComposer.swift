//
//  EntryComposer.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import SwiftUI

struct EntryComposer: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: TorchTheme
    @EnvironmentObject private var haptics: HapticsWhistle

    // Inputs
    let participants: [Person]
    let payerPrefill: Person?
    let editingItem: LineItem?
    let onSave: (LineItem) -> Void

    // State
    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var category: ExpenseCategory = .food
    @State private var payerId: UUID?
    @State private var consumers: Set<UUID> = []
    @State private var method: Method = .equal
    @State private var weights: [UUID: String] = [:]
    @State private var exacts: [UUID: String] = [:]

    // Engine
    private let engine = SplitEngine()

    // MARK: - Inits
    init(participants: [Person],
         payerPrefill: Person? = nil,
         editingItem: LineItem? = nil,
         onSave: @escaping (LineItem) -> Void) {
        self.participants = participants
        self.payerPrefill = payerPrefill
        self.editingItem = editingItem
        self.onSave = onSave
    }

    // MARK: - Lightweight bindings
    private var payerBinding: Binding<UUID?> {
        Binding(
            get: { payerId ?? participants.first?.id },
            set: { payerId = $0 }
        )
    }

    private func consumerBinding(_ id: UUID) -> Binding<Bool> {
        Binding(
            get: { consumers.contains(id) },
            set: { on in
                if on { consumers.insert(id) } else { consumers.remove(id) }
            }
        )
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    generalCard
                    consumersCard
                    splitCard
                    saveHint
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Rectangle().fill(theme.arenaBackground).ignoresSafeArea())
            .navigationTitle(editingItem == nil ? "Add Expense" : "Edit Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTapped() }
                        .disabled(!canSave)
                }
            }
            .onAppear { bootstrap() }
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 10) {
            categoryGlyph(category)
                .frame(width: 22, height: 22)
                .foregroundStyle(theme.accentColor)
            Text("Expense details")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
            Spacer()
        }
    }

    private var generalCard: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Title").font(.headline).foregroundStyle(theme.textPrimary)
                TextField("e.g., Pizza", text: $title)
                    .textInputAutocapitalization(.words)
                    .padding(10)
                    .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Amount").font(.headline).foregroundStyle(theme.textPrimary)
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
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Category").font(.headline).foregroundStyle(theme.textPrimary)
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
                Text("Payer").font(.headline).foregroundStyle(theme.textPrimary)
                Picker("", selection: payerBinding) {
                    ForEach(participants, id: \.id) { p in
                        Text(p.name).tag(p.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
                .padding(10)
                .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(14)
        .background(theme.cardBackground.opacity(0.6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var consumersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Consumers")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

            VStack(spacing: 8) {
                ForEach(participants, id: \.id) { p in
                    Toggle(p.name, isOn: consumerBinding(p.id))
                        .tint(theme.accentColor)
                }
            }
            .padding(10)
            .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(14)
        .background(theme.cardBackground.opacity(0.6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var splitCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Split")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

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
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .background(theme.cardBackground.opacity(0.6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var weightsEditor: some View {
        let selected = participants.filter { consumers.contains($0.id) }
        return VStack(alignment: .leading, spacing: 8) {
            Text("Relative weights (e.g., 1, 2, 1.5)")
                .font(.footnote)
                .foregroundStyle(theme.textSecondary)

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
                .padding(.vertical, 4)
            }
        }
    }

    private var exactsEditor: some View {
        let selected = participants.filter { consumers.contains($0.id) }
        let sym = MoneyUnits.shared.selected.symbol
        return VStack(alignment: .leading, spacing: 8) {
            Text("Exact amounts (\(sym))")
                .font(.footnote)
                .foregroundStyle(theme.textSecondary)

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
                .padding(.vertical, 4)
            }

            let total = totalExactEntered
            if total > 0 {
                Divider().background(theme.border)
                HStack {
                    Text("Entered total")
                    Spacer()
                    Text(MoneyUnits.shared.format(total))
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var saveHint: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Currency: \(MoneyUnits.shared.selected.code)")
                .font(.footnote)
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Actions & Logic

    private var canSave: Bool {
        guard payerId != nil else { return false }
        let amount = MoneyUnits.shared.parse(amountText)
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               amount > 0 &&
               !consumers.isEmpty
    }

    private func saveTapped() {
        guard let pid = payerId,
              let payer = participants.first(where: { $0.id == pid }) else { return }

        let amount = MoneyUnits.shared.parse(amountText)
        guard amount > 0 else { return }

        let selected = participants.filter { consumers.contains($0.id) }

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
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                total: amount,
                category: category,
                payer: payer,
                consumers: selected,
                method: splitMethod
            )
            onSave(item)
            haptics.success()
            dismiss()
        } catch {
            haptics.error()
        }
    }

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

    private func bootstrap() {
        if let item = editingItem {
            title = item.title
            amountText = MoneyUnits.shared
                .format(item.amount)
                .replacingOccurrences(of: MoneyUnits.shared.selected.symbol, with: "")
                .trimmingCharacters(in: .whitespaces)
            category = item.category
            payerId = item.payerId
            consumers = Set(item.consumerIds)
            switch item.method {
            case .equal: method = .equal
            case .weights(let map):
                method = .weights
                weights = map.mapValues { "\($0)" }
            case .exact(let map):
                method = .exact
                exacts = map.mapValues { "\($0)" }
            }
        } else {
            title = ""
            amountText = ""
            category = .food
            payerId = payerPrefill?.id ?? participants.first?.id
            consumers = Set(participants.map { $0.id })
            method = .equal
        }
    }

    enum Method: String, Hashable { case equal, weights, exact }
}
