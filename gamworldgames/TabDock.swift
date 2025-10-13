//
//  TabDock.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import SwiftUI

struct TabDock: View {
    @EnvironmentObject private var theme: TorchTheme
    @EnvironmentObject private var haptics: HapticsWhistle

    @State private var selection: Tab = .home

    enum Tab: Hashable {
        case home, sessions, live, stats, settings
    }

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                HomeBoard()
                    .navigationTitle("Home")
                    .background(
                        Rectangle().fill(theme.arenaBackground).ignoresSafeArea()
                    )
            }
            .tabItem { GlyphPack.tabHome(); Text("Home") }
            .tag(Tab.home)

            NavigationStack {
                SessionList()
                    .navigationTitle("Sessions")
                    .background(
                        Rectangle().fill(theme.arenaBackground).ignoresSafeArea()
                    )
            }
            .tabItem { GlyphPack.tabSessions(); Text("Sessions") }
            .tag(Tab.sessions)

            NavigationStack {
                LiveSplit()
                    .navigationTitle("Live Split")
                    .background(
                        Rectangle().fill(theme.arenaBackground).ignoresSafeArea()
                    )
            }
            .tabItem { GlyphPack.coin(); Text("Live") }
            .tag(Tab.live)

            NavigationStack {
                StatsBrief()
                    .navigationTitle("Stats")
                    .background(
                        Rectangle().fill(theme.arenaBackground).ignoresSafeArea()
                    )
            }
            .tabItem { GlyphPack.tabStats(); Text("Stats") }
            .tag(Tab.stats)

            NavigationStack {
                SettingsPad()
                    .navigationTitle("Settings")
                    .background(
                        Rectangle().fill(theme.arenaBackground).ignoresSafeArea()
                    )
            }
            .tabItem { GlyphPack.tabSettings(); Text("Settings") }
            .tag(Tab.settings)
        }
        .tint(theme.accentColor)
        .onChange(of: selection) { _ in haptics.selection() }
    }
}
