//
//  ThermalStatus.swift
//  MacStat
//

import Foundation

/// Тепловое состояние macOS; само по себе не доказывает снижение частот.
nonisolated enum ThermalStatus: Int, Codable, Sendable {
    case normal
    case elevated
    case high
    case critical

    /// Название состояния для интерфейса.
    var title: LocalizedStringResource {
        switch self {
        case .normal: "Normal"
        case .elevated: "Elevated"
        case .high: "High"
        case .critical: "Critical"
        }
    }

    /// Нужно ли предупреждение в меню-баре.
    var needsWarning: Bool {
        self == .high || self == .critical
    }
}
