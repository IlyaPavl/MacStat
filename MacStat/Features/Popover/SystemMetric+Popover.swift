//
//  SystemMetric+Popover.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

extension SystemMetric {
    /// Порядок карточек в поповере: пары по строкам, нечётная последняя растягивается.
    static let popoverOrder: [SystemMetric] = [.cpuLoad, .cpuTemperature, .gpuTemperature, .fanSpeed, .memory]

    /// Цвет графика и подсветки карточки.
    var tint: Color {
        switch self {
        case .cpuLoad: .blue
        case .cpuTemperature: .orange
        case .fanSpeed: .teal
        case .gpuTemperature: .pink
        case .memory: .purple
        }
    }

    /// Фиксированный диапазон графика; `nil` — по данным.
    var chartRange: ClosedRange<Double>? {
        switch self {
        case .cpuLoad, .memory: 0...1
        case .cpuTemperature, .fanSpeed, .gpuTemperature: nil
        }
    }

    /// Крупное значение в карточке.
    func valueText(in snapshot: SystemSnapshot) -> Text {
        let value = value(in: snapshot)
        return switch self {
        case .cpuLoad, .memory:
            Text(verbatim: MetricFormatter.percent(value))
        case .cpuTemperature, .gpuTemperature:
            Text(verbatim: MetricFormatter.shortTemperature(value))
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
