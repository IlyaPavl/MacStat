//
//  MenuBarMetric.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Foundation

/// Метрика, которую можно вывести в меню-бар.
enum MenuBarMetric: String, CaseIterable, Identifiable {
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

    /// Название в настройках.
    var title: LocalizedStringResource {
        switch self {
        case .cpuLoad: "CPU load"
        case .cpuTemperature: "CPU temperature"
        case .fanSpeed: "Fan speed"
        case .gpuTemperature: "GPU temperature"
        case .memory: "Memory used"
        }
    }

    /// Подпись над значением в двухстрочном стиле; не локализуется.
    var caption: String {
        switch self {
        case .cpuLoad: "CPU"
        case .cpuTemperature: "CPU°"
        case .fanSpeed: "FAN"
        case .gpuTemperature: "GPU°"
        case .memory: "RAM"
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
}
