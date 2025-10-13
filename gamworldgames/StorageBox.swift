//
//  StorageBox.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import SwiftUI
import Combine

final class StorageBox: ObservableObject {
    // MARK: - User Preferences
    @AppStorage("isDarkMode") var isDarkMode: Bool = true
    @AppStorage("preferredAccent") var preferredAccent: String = "blue"
    @AppStorage("preferredCurrency") var preferredCurrency: String = "USD"
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true

    // MARK: - Data
    @Published var sessions: [ExpenseSession] = []

    private let sessionsKey = "storedSessions"

    init() {
        loadSessions()
    }

    // MARK: - Theme
    func updateDarkMode(_ enabled: Bool) {
        isDarkMode = enabled
    }

    func updateAccent(_ accent: String) {
        preferredAccent = accent
    }

    func updateCurrency(_ code: String) {
        preferredCurrency = code
    }

    func updateHaptics(_ enabled: Bool) {
        hapticsEnabled = enabled
    }

    // MARK: - Expense Sessions
    func addSession(_ session: ExpenseSession) {
        sessions.insert(session, at: 0)
        saveSessions()
    }

    func updateSession(_ session: ExpenseSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
            saveSessions()
        }
    }

    func deleteSession(_ session: ExpenseSession) {
        sessions.removeAll { $0.id == session.id }
        saveSessions()
    }

    func clearAll() {
        sessions.removeAll()
        saveSessions()
    }

    // MARK: - Persistence
    func saveSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
    }

    func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey),
              let decoded = try? JSONDecoder().decode([ExpenseSession].self, from: data)
        else { return }
        sessions = decoded
    }

    func flush() {
        saveSessions()
    }

    // MARK: - Sync AppStorage
    func applyAppStorage() {
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        preferredAccent = UserDefaults.standard.string(forKey: "preferredAccent") ?? "blue"
        preferredCurrency = UserDefaults.standard.string(forKey: "preferredCurrency") ?? "USD"
        hapticsEnabled = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }
}
