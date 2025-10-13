//
//  SessionEditor.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import SwiftUI

struct SessionEditor: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: TorchTheme
    @EnvironmentObject private var haptics: HapticsWhistle

    // Input/Output
    private let existing: ExpenseSession?
    private let onSave: (ExpenseSession) -> Void

    // State
    @State private var title: String = ""
    @State private var date: Date = Date()
    @State private var people: [Person] = []
    @State private var selected: Set<UUID> = []
    @State private var addPersonText: String = ""

    // Currency is taken from MoneyUnits at save time
    private var currencyCode: String { MoneyUnits.shared.selected.code }

    // MARK: - Inits

    init(existing: ExpenseSession? = nil, onSave: @escaping (ExpenseSession) -> Void) {
        self.existing = existing
        self.onSave = onSave
    }

    // Convenience init used by callers without an existing session
    init(onSave: @escaping (ExpenseSession) -> Void) {
        self.init(existing: nil, onSave: onSave)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Rectangle().fill(theme.arenaBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    header
                    titleCard
                    dateCard
                    peopleCard
                    footerHint
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle(existing == nil ? "New Session" : "Edit Session")
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

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 10) {
            GlyphPack.tabSessions(size: 24)
                .foregroundStyle(theme.accentColor)
            Text("Hangout details")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
            Spacer()
        }
    }

    private var titleCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Title").font(.headline).foregroundStyle(theme.textPrimary)
            TextField("e.g., Derby Night", text: $title)
                .textInputAutocapitalization(.words)
                .padding(12)
                .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(14)
        .background(theme.cardBackground.opacity(0.6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var dateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Date").font(.headline).foregroundStyle(theme.textPrimary)
            DatePicker("", selection: $date, displayedComponents: [.date])
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding(12)
                .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(14)
        .background(theme.cardBackground.opacity(0.6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var peopleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Participants")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

            // Add person quick input
            HStack(spacing: 8) {
                TextField("Add person", text: $addPersonText)
                    .textInputAutocapitalization(.words)
                    .padding(10)
                    .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                Button {
                    addPerson()
                } label: {
                    GlyphPack.add(size: 20)
                        .foregroundStyle(theme.textPrimary)
                        .padding(10)
                        .background(
                            Capsule().fill(
                                LinearGradient(colors: [theme.accentColor.opacity(0.25),
                                                        theme.accentColor.opacity(0.08)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                        )
                }
                .buttonStyle(.plain)
                .disabled(addPersonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            // List of people with toggles
            VStack(spacing: 8) {
                ForEach(people, id: \.id) { p in
                    HStack {
                        Toggle(isOn: Binding(
                            get: { selected.contains(p.id) },
                            set: { on in
                                if on { selected.insert(p.id) } else { selected.remove(p.id) }
                                haptics.selection()
                            })
                        ) {
                            Text(p.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(theme.textPrimary)
                        }
                        .tint(theme.accentColor)

                        Spacer()

                        Button {
                            removePerson(p)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(ColorRack.red.opacity(0.9))
                    }
                    .padding(10)
                    .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(14)
        .background(theme.cardBackground.opacity(0.6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var footerHint: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Currency: \(currencyCode)")
                .font(.footnote)
                .foregroundStyle(theme.textSecondary)
            Text("You can change currency in Settings.")
                .font(.footnote)
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Actions

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selected.isEmpty
    }

    private func saveTapped() {
        let participants = people.filter { selected.contains($0.id) }
        var session = existing ?? ExpenseSession(title: title, currencyCode: currencyCode, participants: participants)
        session.title = title
        session.date = date
        session.currencyCode = currencyCode
        session.participants = participants
        onSave(session)
        haptics.success()
        dismiss()
    }

    private func addPerson() {
        let trimmed = addPersonText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        PeopleHub.shared.addPerson(trimmed)
        addPersonText = ""
        reloadPeople()
        if let newly = people.last { selected.insert(newly.id) }
        haptics.selection()
    }

    private func removePerson(_ p: Person) {
        PeopleHub.shared.removePerson(p.id)
        selected.remove(p.id)
        reloadPeople()
        haptics.warning()
    }

    // MARK: - Bootstrap

    private func bootstrap() {
        reloadPeople()
        if let s = existing {
            title = s.title
            date = s.date
            selected = Set(s.participants.map { $0.id })
        } else {
            title = ""
            date = Date()
            let defaults = PeopleHub.shared.allPeople()
            selected = Set(defaults.map { $0.id })
        }
    }

    private func reloadPeople() {
        people = PeopleHub.shared.allPeople()
    }
}
