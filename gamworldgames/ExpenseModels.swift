//
//  ExpenseModels.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import Foundation

// MARK: - ExpenseCategory

enum ExpenseCategory: String, CaseIterable, Codable, Hashable {
    case food, drinks, ride, tickets, merch, other

    var title: String {
        switch self {
        case .food: return "Food"
        case .drinks: return "Drinks"
        case .ride: return "Ride"
        case .tickets: return "Tickets"
        case .merch: return "Merch"
        case .other: return "Other"
        }
    }
}

// MARK: - LineItem

struct LineItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var amount: Decimal
    var category: ExpenseCategory
    var payerId: UUID
    var consumerIds: [UUID]
    var method: SplitMethod

    init(title: String,
         amount: Decimal,
         category: ExpenseCategory,
         payer: Person,
         consumers: [Person],
         method: SplitMethod) {
        self.id = UUID()
        self.title = title
        self.amount = amount
        self.category = category
        self.payerId = payer.id
        self.consumerIds = consumers.map { $0.id }
        self.method = method
    }
}

// MARK: - ExpenseSession

struct ExpenseSession: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var date: Date
    var currencyCode: String
    var participants: [Person]
    var items: [LineItem]

    init(title: String,
         currencyCode: String,
         participants: [Person]) {
        self.id = UUID()
        self.title = title
        self.date = Date()
        self.currencyCode = currencyCode
        self.participants = participants
        self.items = []
    }

    var totalAmount: Decimal {
        items.reduce(0) { $0 + $1.amount }.roundedMoney()
    }
}

// MARK: - SplitMethod

enum SplitMethod: Codable, Hashable {
    case equal
    case weights([UUID: Decimal])
    case exact([UUID: Decimal])

    private enum CodingKeys: String, CodingKey { case type, map }

    enum MethodType: String, Codable {
        case equal, weights, exact
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MethodType.self, forKey: .type)
        switch type {
        case .equal:
            self = .equal
        case .weights:
            let map = try container.decode([UUID: Decimal].self, forKey: .map)
            self = .weights(map)
        case .exact:
            let map = try container.decode([UUID: Decimal].self, forKey: .map)
            self = .exact(map)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .equal:
            try container.encode(MethodType.equal, forKey: .type)
        case .weights(let map):
            try container.encode(MethodType.weights, forKey: .type)
            try container.encode(map, forKey: .map)
        case .exact(let map):
            try container.encode(MethodType.exact, forKey: .type)
            try container.encode(map, forKey: .map)
        }
    }
}
