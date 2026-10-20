//
//  SystemMetric+MenuBar.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

extension SystemMetric {
    /// Подпись над значением в двухстрочном стиле; не локализуется.
    var menuBarCaption: String {
        switch self {
        case .cpuLoad: "CPU"
        case .cpuTemperature: "CPU°"
        case .chipPower: "PWR"
        case .fanSpeed: "FAN"
        case .gpuTemperature: "GPU°"
        case .batteryTemperature: "BAT°"
        case .memory: "RAM"
        }
    }

    /// Метрика, которую естественно показать под этой в столбце.
    nonisolated var stackPartner: SystemMetric {
        switch self {
        case .cpuLoad: .cpuTemperature
        case .cpuTemperature, .memory: .cpuLoad
        case .chipPower: .cpuTemperature
        case .fanSpeed: .gpuTemperature
        case .gpuTemperature: .fanSpeed
        case .batteryTemperature: .chipPower
        }
    }

    /// Короткий текст значения для меню-бара.
    func menuBarText(in snapshot: SystemSnapshot) -> String {
        menuBarText(for: value(in: snapshot))
    }

    /// Самое широкое возможное значение — по нему резервируется ширина колонки.
    var widestMenuBarText: String {
        switch self {
        case .cpuLoad, .memory: menuBarText(for: 1)
        case .cpuTemperature, .gpuTemperature, .batteryTemperature: menuBarText(for: 100)
        case .chipPower: menuBarText(for: 188)
        case .fanSpeed: menuBarText(for: 8_800)
        }
    }

    /// Форматирует значение в стиле этой метрики.
    private func menuBarText(for value: Double?) -> String {
        switch self {
        case .cpuLoad, .memory: MetricFormatter.percent(value)
        case .cpuTemperature, .gpuTemperature, .batteryTemperature: MetricFormatter.shortTemperature(value)
        case .chipPower: MetricFormatter.shortPower(value)
        case .fanSpeed: MetricFormatter.shortFanSpeed(value)
        }
    }
}
