//
//  MoneyUnits.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import Foundation
import Combine


struct CurrencyInfo: Identifiable, Codable, Hashable {
    let id = UUID()
    let code: String
    let symbol: String
    let name: String
}

final class MoneyUnits {
    static let shared = MoneyUnits()
    private init() { select(code: "USD") }

    private(set) var selected: CurrencyInfo = CurrencyInfo(code: "USD", symbol: "$", name: "US Dollar")

    let all: [CurrencyInfo] = [
        CurrencyInfo(code: "USD", symbol: "$", name: "US Dollar"),
        CurrencyInfo(code: "EUR", symbol: "€", name: "Euro"),
        CurrencyInfo(code: "GBP", symbol: "£", name: "Pound Sterling"),
        CurrencyInfo(code: "JPY", symbol: "¥", name: "Japanese Yen"),
        CurrencyInfo(code: "CHF", symbol: "CHF", name: "Swiss Franc"),
        CurrencyInfo(code: "CAD", symbol: "$", name: "Canadian Dollar"),
        CurrencyInfo(code: "AUD", symbol: "$", name: "Australian Dollar")
    ]

    func select(code: String) {
        if let found = all.first(where: { $0.code == code }) {
            selected = found
        }
    }

    func format(_ value: Decimal) -> String {
        let num = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = selected.code
        formatter.currencySymbol = selected.symbol
        formatter.maximumFractionDigits = 2
        return formatter.string(from: num) ?? "\(selected.symbol)\(num)"
    }

    func parse(_ text: String) -> Decimal {
        let clean = text
            .replacingOccurrences(of: selected.symbol, with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Decimal(string: clean) ?? 0
    }
}

// MARK: - Decimal helper

extension Decimal {
    func roundedMoney(_ scale: Int = 2) -> Decimal {
        var x = self
        var y = Decimal()
        NSDecimalRound(&y, &x, scale, .bankers)
        return y
    }
}
