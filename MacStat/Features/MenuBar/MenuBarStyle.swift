//
//  MenuBarStyle.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Foundation

/// Вид значка в меню-баре.
enum MenuBarStyle: String, CaseIterable, Identifiable {
    /// Две строки: подпись и значение.
    case compact
    /// Иконка и значение в строку.
    case iconsAndValues
    /// Только иконка приложения.
    case iconOnly

    /// Идентификатор для `ForEach`.
    var id: Self { self }

    /// Название в настройках.
    var title: LocalizedStringResource {
        switch self {
        case .compact: "Two rows"
        case .iconsAndValues: "Icons and values"
        case .iconOnly: "Icon only"
        }
    }

    /// Показывает ли стиль значения.
    var showsValues: Bool {
        self != .iconOnly
    }
}
