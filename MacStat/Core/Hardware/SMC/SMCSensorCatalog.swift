//
//  SMCSensorCatalog.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

/// Датчики, найденные при первом замере.
nonisolated struct SMCSensorCatalog: Sendable {
    /// Температуры CPU.
    let cpuTemperatureSensors: [SMCSensor]
    /// Температуры GPU.
    let gpuTemperatureSensors: [SMCSensor]
    /// Обороты вентиляторов.
    let fanSensors: [SMCSensor]
    /// Температуры батареи.
    let batteryTemperatureSensors: [SMCSensor]
    /// Оценка мощности чипа.
    let chipPowerSensors: [SMCSensor]

    /// Пустой каталог, если SMC недоступен.
    static let empty = SMCSensorCatalog(
        cpuTemperatureSensors: [],
        gpuTemperatureSensors: [],
        fanSensors: [],
        batteryTemperatureSensors: [],
        chipPowerSensors: []
    )
}
