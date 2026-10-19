//
//  MetricHistory.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

/// Последние значения метрики для графика, от старых к новым.
nonisolated struct MetricHistory: Equatable, Sendable {
    /// Сколько значений хранить.
    let capacity: Int
    /// Значения, от старых к новым.
    private(set) var values: [Double] = []

    /// Пустая история заданной ёмкости (минимум 1).
    init(capacity: Int) {
        self.capacity = max(capacity, 1)
        values.reserveCapacity(self.capacity)
    }

    /// Добавляет значение, вытесняя самое старое.
    mutating func append(_ value: Double) {
        if values.count == capacity {
            values.removeFirst()
        }
        values.append(value)
    }
}
