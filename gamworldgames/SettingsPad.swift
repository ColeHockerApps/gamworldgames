//
//  SettingsPad.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import SwiftUI

struct SettingsPad: View {
    @EnvironmentObject private var theme: TorchTheme
    @EnvironmentObject private var storage: StorageBox
    @EnvironmentObject private var haptics: HapticsWhistle
    @Environment(\.openURL) private var openURL

    // AppStorage mirrors for instant UI reaction
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true
    @AppStorage("preferredAccent") private var preferredAccent: String = "blue"
    @AppStorage("preferredCurrency") private var preferredCurrency: String = "USD"
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true

    // Local UI state
    @State private var selectedAccent: TorchTheme.Accent = .blue
    @State private var selectedCurrency: CurrencyInfo = MoneyUnits.shared.selected

    // Change this to your live doc URL
    private let privacyURLString = "https://example.com/gamworldgames/privacy"

    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle().fill(theme.arenaBackground).ignoresSafeArea()

                Form {
                    Section("Appearance") {
                        Toggle(isOn: Binding(
                            get: { isDarkMode },
                            set: { value in
                                isDarkMode = value
                                storage.isDarkMode = value
                                value ? theme.applyDarkMode() : theme.applyLightMode()
                                haptics.selection()
                            })
                        ) {
                            Text("Dark Mode")
                        }

                        Picker("Accent", selection: Binding(
                            get: { selectedAccent },
                            set: { value in
                                selectedAccent = value
                                theme.setAccent(value)
                                let key = accentKey(value)
                                preferredAccent = key
                                storage.preferredAccent = key
                                haptics.selection()
                            })
                        ) {
                            ForEach(TorchTheme.Accent.allCases, id: \.self) { a in
                                HStack {
                                    Circle()
                                        .fill(swatch(for: a)) // <- fixed
                                        .frame(width: 14, height: 14)
                                    Text(accentTitle(a))
                                }
                                .tag(a)
                            }
                        }
                    }

                    Section("Preferences") {
                        Toggle(isOn: Binding(
                            get: { hapticsEnabled },
                            set: { value in
                                hapticsEnabled = value
                                storage.hapticsEnabled = value
                                haptics.isEnabled = value
                                haptics.selection()
                            })
                        ) {
                            Text("Haptics")
                        }

                        Picker("Currency", selection: Binding(
                            get: { selectedCurrency },
                            set: { info in
                                selectedCurrency = info
                                MoneyUnits.shared.select(code: info.code)
                                preferredCurrency = info.code
                                storage.preferredCurrency = info.code
                                haptics.selection()
                            })
                        ) {
                            ForEach(MoneyUnits.shared.all) { info in
                                Text("\(info.code) \(info.symbol) — \(info.name)").tag(info)
                            }
                        }
                    }

                    Section("Privacy") {
                        Button {
                            if let url = URL(string: privacyURLString) {
                                openURL(url)
                                haptics.selection()
                            }
                        } label: {
                            HStack(spacing: 10) {
                                GlyphPack.privacy(size: 18)
                                Text("Open Privacy Policy")
                            }
                        }
                    }

                    Section("Data") {
                        Button(role: .destructive) {
                            storage.clearAll()
                            // Re-sync UI with defaults after wipe
                            syncFromStorage()
                            haptics.warning()
                        } label: {
                            Label("Clear Local Data", systemImage: "trash")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .onAppear {
                syncFromStorage()
            }
        }
    }

    // MARK: - Sync

    private func syncFromStorage() {
        // StorageBox already persists values; reflect them in AppStorage & UI
        isDarkMode = storage.isDarkMode
        hapticsEnabled = storage.hapticsEnabled
        preferredAccent = storage.preferredAccent
        preferredCurrency = storage.preferredCurrency

        // Apply theme & currency
        if let a = accentFrom(preferredAccent) { selectedAccent = a; theme.setAccent(a) }
        MoneyUnits.shared.select(code: preferredCurrency)
        selectedCurrency = MoneyUnits.shared.selected

        // Apply dark/light visuals
        isDarkMode ? theme.applyDarkMode() : theme.applyLightMode()
        haptics.isEnabled = hapticsEnabled
    }

    // MARK: - Helpers

    private func swatch(for a: TorchTheme.Accent) -> Color {
        switch a {
        case .blue:   return ColorRack.blue
        case .mint:   return ColorRack.mint
        case .violet: return ColorRack.violet
        case .orange: return ColorRack.orange
        case .red:    return ColorRack.red
        case .gold:   return ColorRack.gold
        case .teal:   return ColorRack.teal
        }
    }

    private func accentFrom(_ key: String) -> TorchTheme.Accent? {
        switch key.lowercased() {
        case "blue": return .blue
        case "mint": return .mint
        case "violet": return .violet
        case "orange": return .orange
        case "red": return .red
        case "gold": return .gold
        case "teal": return .teal
        default: return nil
        }
    }

    private func accentKey(_ a: TorchTheme.Accent) -> String {
        switch a {
        case .blue: return "blue"
        case .mint: return "mint"
        case .violet: return "violet"
        case .orange: return "orange"
        case .red: return "red"
        case .gold: return "gold"
        case .teal: return "teal"
        }
    }

    private func accentTitle(_ a: TorchTheme.Accent) -> String {
        switch a {
        case .blue: return "Blue"
        case .mint: return "Mint"
        case .violet: return "Violet"
        case .orange: return "Orange"
        case .red: return "Red"
        case .gold: return "Gold"
        case .teal: return "Teal"
        }
    }
}
