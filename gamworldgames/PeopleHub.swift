//
//  PeopleHub.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import Foundation

struct Person: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String

    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}

final class PeopleHub {
    static let shared = PeopleHub()
    private init() {}

    private let key = "storedPeople"
    private(set) var people: [Person] = []

    // MARK: - Load / Save
    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Person].self, from: data)
        else { return }
        people = decoded
    }

    func save() {
        if let data = try? JSONEncoder().encode(people) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: - Access
    func allPeople() -> [Person] {
        if people.isEmpty {
            load()
        }
        if people.isEmpty {
            // Default sample
            people = [
                Person(name: "Alex"),
                Person(name: "Jamie"),
                Person(name: "Taylor")
            ]
            save()
        }
        return people
    }

    func addPerson(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newPerson = Person(name: trimmed)
        people.append(newPerson)
        save()
    }

    func removePerson(_ id: UUID) {
        people.removeAll { $0.id == id }
        save()
    }

    func renamePerson(_ id: UUID, to newName: String) {
        guard let index = people.firstIndex(where: { $0.id == id }) else { return }
        people[index].name = newName
        save()
    }
}
