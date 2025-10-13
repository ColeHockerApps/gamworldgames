//
//  SessionList.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import SwiftUI

struct SessionList: View {
    @EnvironmentObject private var theme: TorchTheme
    @EnvironmentObject private var storage: StorageBox
    @EnvironmentObject private var haptics: HapticsWhistle

    @State private var showAdd = false
    @State private var editing: ExpenseSession?

    var body: some View {
        ZStack {
            Rectangle().fill(theme.arenaBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                if storage.sessions.isEmpty {
                    emptyState
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                } else {
                    List {
                        ForEach(storage.sessions) { session in
                            NavigationLink {
                                SessionDetail(session: session)
                                    .environmentObject(theme)
                                    .environmentObject(storage)
                                    .environmentObject(haptics)
                            } label: {
                                row(session)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    storage.deleteSession(session)
                                    haptics.warning()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    editing = session
                                    haptics.selection()
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(theme.accentColor)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
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
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                SessionEditor { newSession in
                    storage.addSession(newSession)
                    haptics.success()
                    showAdd = false
                }
                .environmentObject(theme)
                .environmentObject(storage)
                .environmentObject(haptics)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $editing) { session in
            NavigationStack {
                SessionEditor(existing: session) { updated in
                    storage.updateSession(updated)
                    haptics.success()
                    editing = nil
                }
                .environmentObject(theme)
                .environmentObject(storage)
                .environmentObject(haptics)
            }
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Row

    private func row(_ s: ExpenseSession) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                GlyphPack.tabSessions(size: 22)
                    .foregroundStyle(theme.accentColor)
                Text(s.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                Text(MoneyUnits.shared.format(s.totalAmount))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
            }
            HStack(spacing: 8) {
                Text(s.date.formatted(date: .abbreviated, time: .omitted))
                Text("•")
                Text("\(s.items.count) items")
                Text("•")
                Text("\(s.participants.count) people")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(theme.textSecondary)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 14) {
            GlyphPack.tabSessions(size: 36)
                .foregroundStyle(theme.accentColor)
            Text("No sessions yet")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(theme.textPrimary)
            Text("Create your first hangout and start adding expenses.")
                .font(.system(size: 13))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                showAdd = true
                haptics.selection()
            } label: {
                Label("Add New Session", systemImage: "plus.circle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .background(
                        Capsule().fill(
                            LinearGradient(colors: [theme.accentColor.opacity(0.25),
                                                    theme.accentColor.opacity(0.08)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
