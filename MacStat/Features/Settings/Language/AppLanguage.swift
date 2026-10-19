//
//  AppLanguage.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Foundation

/// Язык интерфейса приложения.
enum AppLanguage: Hashable, Identifiable {
    /// Как в системе.
    case system
    /// Конкретная локализация, например `ru`.
    case specific(String)

    /// Идентификатор для `ForEach`.
    var id: Self { self }

    /// Код локализации; `nil` — системный язык.
    var identifier: String? {
        switch self {
        case .system: nil
        case .specific(let identifier): identifier
        }
    }

    /// Название для выбора: «Системный» или самоназвание языка.
    var displayName: String {
        switch self {
        case .system:
            String(localized: "System")
        case .specific(let identifier):
            Locale(identifier: identifier).localizedString(forIdentifier: identifier)?
                .capitalized(with: Locale(identifier: identifier)) ?? identifier
        }
    }
}
