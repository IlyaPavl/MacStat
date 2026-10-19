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
        case .fanSpeed: "FAN"
        case .gpuTemperature: "GPU°"
        case .memory: "RAM"
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
        case .cpuTemperature, .gpuTemperature: menuBarText(for: 100)
        case .fanSpeed: menuBarText(for: 8_800)
        }
    }

    /// Форматирует значение в стиле этой метрики.
    private func menuBarText(for value: Double?) -> String {
        switch self {
        case .cpuLoad, .memory: MetricFormatter.percent(value)
        case .cpuTemperature, .gpuTemperature: MetricFormatter.shortTemperature(value)
        case .fanSpeed: MetricFormatter.shortFanSpeed(value)
        }
    }
}
