//
//  MenuBarReading.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

/// Готовый текст одной метрики для меню-бара.
struct MenuBarReading: Equatable {
    /// Метрика.
    let metric: SystemMetric
    /// Отформатированное значение.
    let value: String
}

extension MenuBarReading {
    /// Текст метрики в замере.
    init(metric: SystemMetric, snapshot: SystemSnapshot) {
        self.init(metric: metric, value: metric.menuBarText(in: snapshot))
    }
}
