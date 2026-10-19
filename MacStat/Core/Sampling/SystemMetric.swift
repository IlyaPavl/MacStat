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
    /// Обороты вентилятора.
    case fanSpeed
    /// Температура GPU.
    case gpuTemperature
    /// Занятая память.
    case memory

    /// Идентификатор для `ForEach`.
    var id: Self { self }

    /// Название для интерфейса.
    var title: LocalizedStringResource {
        switch self {
        case .cpuLoad: "CPU load"
        case .cpuTemperature: "CPU temperature"
        case .fanSpeed: "Fan speed"
        case .gpuTemperature: "GPU temperature"
        case .memory: "Memory used"
        }
    }

    /// Имя SF Symbol.
    var symbolName: String {
        switch self {
        case .cpuLoad: "cpu"
        case .cpuTemperature: "thermometer.medium"
        case .fanSpeed: "fan"
        case .gpuTemperature: "square.stack.3d.up"
        case .memory: "memorychip"
        }
    }

    /// Числовое значение метрики в замере: доли 0...1, °C или об/мин.
    func value(in snapshot: SystemSnapshot) -> Double? {
        switch self {
        case .cpuLoad: snapshot.cpuLoad
        case .cpuTemperature: snapshot.cpuTemperature
        case .fanSpeed: snapshot.fanSpeed
        case .gpuTemperature: snapshot.gpuTemperature
        case .memory: snapshot.memoryUsage?.usedFraction
        }
    }
}
