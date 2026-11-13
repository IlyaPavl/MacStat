//
//  SystemMetric+Popover.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

extension SystemMetric {
    /// Порядок карточек в поповере: пары по строкам, нечётная последняя растягивается.
    static let popoverOrder: [SystemMetric] = [
        .cpuLoad, .cpuTemperature, .chipPower, .gpuTemperature, .fanSpeed, .batteryTemperature, .memory,
    ]

    /// Цвет графика и подсветки карточки.
    var tint: Color {
        switch self {
        case .cpuLoad: .blue
        case .cpuTemperature: .orange
        case .chipPower: .yellow
        case .fanSpeed: .teal
        case .gpuTemperature: .pink
        case .batteryTemperature: .green
        case .memory: .purple
        }
    }

    /// Базовый диапазон графика; верхняя граница растёт, если значения выходят за неё.
    var chartRange: ClosedRange<Double> {
        switch self {
        case .cpuLoad, .memory: 0...1
        case .cpuTemperature, .gpuTemperature, .batteryTemperature: 0...100
        case .chipPower: 0...200
        case .fanSpeed: 0...2000
        }
    }

    /// Подпись деления оси графика.
    func axisLabel(for value: Double) -> String {
        switch self {
        case .cpuLoad, .memory: MetricFormatter.percent(value)
        case .cpuTemperature, .gpuTemperature, .batteryTemperature: MetricFormatter.shortTemperature(value)
        case .chipPower: MetricFormatter.shortPower(value)
        case .fanSpeed: MetricFormatter.fullFanSpeed(value)
        }
    }

    /// Крупное значение в карточке.
    func valueText(in snapshot: SystemSnapshot) -> Text {
        let value = value(in: snapshot)
        return switch self {
        case .cpuLoad, .memory:
            Text(verbatim: MetricFormatter.percent(value))
        case .cpuTemperature, .gpuTemperature, .batteryTemperature:
            Text(verbatim: MetricFormatter.shortTemperature(value))
        case .chipPower:
            Text(verbatim: MetricFormatter.fullPower(value))
        case .fanSpeed:
            if let value {
                Text("\(MetricFormatter.fullFanSpeed(value)) rpm")
            } else {
                Text(verbatim: MetricFormatter.missingValue)
            }
        }
    }

    /// Уточнение рядом со значением, например «12 ГБ из 16 ГБ».
    func detailText(in snapshot: SystemSnapshot) -> Text? {
        guard self == .memory, let memoryUsage = snapshot.memoryUsage else { return nil }
        let used = MetricFormatter.memorySize(memoryUsage.usedBytes)
        let total = MetricFormatter.memorySize(memoryUsage.totalBytes)
        return Text("\(used) of \(total)")
    }
}
