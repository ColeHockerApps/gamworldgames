//
//  GamWorldGamesApp.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import SwiftUI

@main
struct GamWorldGamesApp: App {
    // Singletons for the whole app
    @StateObject private var theme = TorchTheme()
    @StateObject private var storage = StorageBox()
    @StateObject private var haptics = HapticsWhistle()

    @Environment(\.scenePhase) private var scenePhase

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    final class AppDelegate: NSObject, UIApplicationDelegate {
        func application(_ application: UIApplication,
                         supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
            if OrientationGate.allowAll {
                return [.portrait, .landscapeLeft, .landscapeRight]
            } else {
                return [.portrait]
            }
        }
    }
    
    
    init() {
        
        
        NotificationCenter.default.post(name: Notification.Name("art.icon.loading.start"), object: nil)
        IconSettings.shared.attach()
        
        // Bootstrap persisted preferences
        storage.applyAppStorage()

        // Theme
        if storage.isDarkMode { theme.applyDarkMode() } else { theme.applyLightMode() }
        if let accent = TorchTheme.Accent(named: storage.preferredAccent) {
            theme.setAccent(accent)
        }

        // Currency
        MoneyUnits.shared.select(code: storage.preferredCurrency)

        // Haptics
        haptics.isEnabled = storage.hapticsEnabled
    }

    var body: some Scene {
        WindowGroup {
            
            TabSettingsView{
                TabDock()
                    .environmentObject(theme)
                    .environmentObject(storage)
                    .environmentObject(haptics)
                    .preferredColorScheme(theme.isDark ? .dark : .light)
                    .onAppear { haptics.warmup() }
                
                
                    .onAppear {
                                        
                        ReviewNudge.shared.schedule(after: 100)
                                 
                    }
                
                
            }
            
            .onAppear {
                OrientationGate.allowAll = false
            }
            
        }
        
        
        
        
        .onChange(of: scenePhase) { phase in
            if phase == .inactive || phase == .background {
                storage.flush() // save any pending changes if your StorageBox supports it
            }
        }
    }
}

// MARK: - Convenience

private extension TorchTheme.Accent {
    init?(named key: String) {
        switch key.lowercased() {
        case "blue": self = .blue
        case "mint": self = .mint
        case "violet": self = .violet
        case "orange": self = .orange
        case "red": self = .red
        case "gold": self = .gold
        case "teal": self = .teal
        default: return nil
        }
    }
}
