//
//  SystemMetric.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Foundation

/// Метрика системы, которую показывает приложение.
nonisolated enum SystemMetric: String, CaseIterable, Codable, Identifiable, Sendable {
    /// Загрузка CPU.
    case cpuLoad
    /// Температура CPU.
    case cpuTemperature
    /// Мощность чипа.
    case chipPower
    /// Обороты вентилятора.
    case fanSpeed
    /// Температура GPU.
    case gpuTemperature
    /// Температура батареи.
    case batteryTemperature
    /// Занятая память.
    case memory

    /// Идентификатор для `ForEach`.
    var id: Self { self }

    /// Название для интерфейса.
    var title: LocalizedStringResource {
        switch self {
        case .cpuLoad: "CPU load"
        case .cpuTemperature: "CPU temperature"
        case .chipPower: "Chip power"
        case .fanSpeed: "Fan speed"
        case .gpuTemperature: "GPU temperature"
        case .batteryTemperature: "Battery temperature"
        case .memory: "Memory used"
        }
    }

    /// Имя SF Symbol.
    var symbolName: String {
        switch self {
        case .cpuLoad: "cpu"
        case .cpuTemperature: "thermometer.medium"
        case .chipPower: "bolt"
        case .fanSpeed: "fan"
        case .gpuTemperature: "square.stack.3d.up"
        case .batteryTemperature: "battery.75percent"
        case .memory: "memorychip"
        }
    }

    /// Есть ли метрика не на каждом Mac: без значения в замере её скрывают.
    var dependsOnHardware: Bool {
        switch self {
        case .chipPower, .fanSpeed, .batteryTemperature: true
        case .cpuLoad, .cpuTemperature, .gpuTemperature, .memory: false
        }
    }

    /// Числовое значение метрики в замере: доли 0...1, °C, Вт или об/мин.
    func value(in snapshot: SystemSnapshot) -> Double? {
        switch self {
        case .cpuLoad: snapshot.cpuLoad
        case .cpuTemperature: snapshot.cpuTemperature
        case .chipPower: snapshot.chipPower
        case .fanSpeed: snapshot.fanSpeed
        case .gpuTemperature: snapshot.gpuTemperature
        case .batteryTemperature: snapshot.batteryTemperature
        case .memory: snapshot.memoryUsage?.usedFraction
        }
    }
}
