//
//  GlyphKit.swift
//  GamWorldGames
//
//  Created on 2025-10-10
//

import SwiftUI
import Combine


// MARK: - GlyphPack
// Centralized access to SF Symbols and custom icons
// Used across UI elements and category indicators.

enum GlyphPack {
    // MARK: - General
    static func add(size: CGFloat = 22) -> some View { Image(systemName: "plus.circle.fill").resizable().scaledToFit().frame(width: size, height: size) }
    static func delete(size: CGFloat = 22) -> some View { Image(systemName: "trash.fill").resizable().scaledToFit().frame(width: size, height: size) }
    static func edit(size: CGFloat = 22) -> some View { Image(systemName: "pencil.circle.fill").resizable().scaledToFit().frame(width: size, height: size) }

    // MARK: - Tabs
    static func tabHome(size: CGFloat = 24) -> some View { Image(systemName: "house.fill").resizable().scaledToFit().frame(width: size, height: size) }
    static func tabSessions(size: CGFloat = 24) -> some View { Image(systemName: "list.bullet.rectangle.portrait.fill").resizable().scaledToFit().frame(width: size, height: size) }
    static func tabStats(size: CGFloat = 24) -> some View { Image(systemName: "chart.bar.fill").resizable().scaledToFit().frame(width: size, height: size) }
    static func tabSettings(size: CGFloat = 24) -> some View { Image(systemName: "gearshape.fill").resizable().scaledToFit().frame(width: size, height: size) }

    // MARK: - Expense Categories
    static func categoryFood(size: CGFloat = 22) -> some View { Image(systemName: "fork.knife.circle.fill").resizable().scaledToFit().frame(width: size, height: size) }
    static func categoryDrinks(size: CGFloat = 22) -> some View { Image(systemName: "cup.and.saucer.fill").resizable().scaledToFit().frame(width: size, height: size) }
    static func categoryRide(size: CGFloat = 22) -> some View { Image(systemName: "car.fill").resizable().scaledToFit().frame(width: size, height: size) }
    static func categoryTickets(size: CGFloat = 22) -> some View { Image(systemName: "ticket.fill").resizable().scaledToFit().frame(width: size, height: size) }
    static func categoryMerch(size: CGFloat = 22) -> some View { Image(systemName: "tshirt.fill").resizable().scaledToFit().frame(width: size, height: size) }
    static func categoryOther(size: CGFloat = 22) -> some View { Image(systemName: "circle.grid.3x3.fill").resizable().scaledToFit().frame(width: size, height: size) }

    // MARK: - Misc
    static func statsTrophy(size: CGFloat = 22) -> some View { Image(systemName: "trophy.fill").resizable().scaledToFit().frame(width: size, height: size) }
    static func statsPerson(size: CGFloat = 22) -> some View { Image(systemName: "person.2.fill").resizable().scaledToFit().frame(width: size, height: size) }
    static func statsCash(size: CGFloat = 22) -> some View { Image(systemName: "banknote.fill").resizable().scaledToFit().frame(width: size, height: size) }
    static func coin(size: CGFloat = 22) -> some View { Image(systemName: "dollarsign.circle.fill").resizable().scaledToFit().frame(width: size, height: size) }

    // MARK: - For settings
    static func privacy(size: CGFloat = 22) -> some View { Image(systemName: "lock.shield.fill").resizable().scaledToFit().frame(width: size, height: size) }
    static func haptics(size: CGFloat = 22) -> some View { Image(systemName: "waveform.circle.fill").resizable().scaledToFit().frame(width: size, height: size) }
    static func theme(size: CGFloat = 22) -> some View { Image(systemName: "circle.lefthalf.fill").resizable().scaledToFit().frame(width: size, height: size) }
}
