//
//  SplitEngine.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import Foundation

// MARK: - SplitEngine
// Handles how a bill is divided among participants

final class SplitEngine {
    func detail(for person: Person, in session: ExpenseSession) -> (paid: Decimal, owes: Decimal, net: Decimal) {
        let paid = session.items
            .filter { $0.payerId == person.id }
            .reduce(0) { $0 + $1.amount }

        var owes: Decimal = 0

        for item in session.items {
            let perPerson = portion(of: item, for: person)
            owes += perPerson
        }

        let net = (paid - owes).roundedMoney()
        return (paid.roundedMoney(), owes.roundedMoney(), net)
    }

    func totalsByCategory(for session: ExpenseSession) -> [ExpenseCategory: Decimal] {
        var dict: [ExpenseCategory: Decimal] = [:]
        for item in session.items {
            dict[item.category, default: 0] += item.amount
        }
        return dict.mapValues { $0.roundedMoney() }
    }

    private func portion(of item: LineItem, for person: Person) -> Decimal {
        guard item.consumerIds.contains(person.id) else { return 0 }

        switch item.method {
        case .equal:
            let share = item.amount / Decimal(item.consumerIds.count)
            return share
        case .weights(let map):
            let totalWeight = map.values.reduce(0, +)
            guard let myWeight = map[person.id], totalWeight > 0 else { return 0 }
            let share = item.amount * (myWeight / totalWeight)
            return share
        case .exact(let map):
            return map[person.id] ?? 0
        }
    }

    // MARK: - Validation and item creation

    func buildLineItem(title: String,
                       total: Decimal,
                       category: ExpenseCategory,
                       payer: Person,
                       consumers: [Person],
                       method: SplitMethod) throws -> LineItem {
        guard total > 0 else { throw SplitError.invalidTotal }
        guard !consumers.isEmpty else { throw SplitError.noConsumers }

        return LineItem(
            title: title,
            amount: total,
            category: category,
            payer: payer,
            consumers: consumers,
            method: method
        )
    }

    enum SplitError: Error {
        case invalidTotal
        case noConsumers
    }
}
