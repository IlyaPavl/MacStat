//
//  SystemSnapshot.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

/// Значения всех метрик в один момент.
nonisolated struct SystemSnapshot: Equatable, Sendable {
    /// Загрузка CPU 0...1.
    var cpuLoad: Double?
    /// Средняя температура CPU, °C.
    var cpuTemperature: Double?
    /// Средняя температура GPU, °C.
    var gpuTemperature: Double?
    /// Средние обороты вентиляторов; `nil` без вентилятора.
    var fanSpeed: Double?
    /// Использование памяти.
    var memoryUsage: MemoryUsage?

    /// Замер без данных.
    static let empty = SystemSnapshot()
}
