//
//  MenuBarReading.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

/// Готовый текст одной метрики для меню-бара.
struct MenuBarReading: Equatable, Identifiable {
    /// Метрика.
    let metric: MenuBarMetric
    /// Отформатированное значение.
    let value: String

    /// Идентификатор — сама метрика.
    var id: MenuBarMetric { metric }
}
