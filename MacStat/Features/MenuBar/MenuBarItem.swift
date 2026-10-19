//
//  MenuBarItem.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Foundation

/// Элемент значка: одна метрика или столбец из двух без подписей.
nonisolated struct MenuBarItem: Codable, Hashable, Identifiable, Sendable {
    /// Стабильный идентификатор — метрики в элементах могут повторяться.
    var id = UUID()
    /// Основная метрика; в столбце — верхняя строка.
    var primary: SystemMetric
    /// Нижняя строка столбца; `nil` — одиночная метрика.
    var secondary: SystemMetric?

    /// Метрики элемента по порядку.
    var metrics: [SystemMetric] {
        [primary] + (secondary.map { [$0] } ?? [])
    }
}
