//
//  MetricFormatter.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Foundation

/// Превращает значения метрик в текст.
nonisolated enum MetricFormatter {
    /// Текст, когда значения нет.
    static let missingValue = "—"

    /// «23%».
    static func percent(_ fraction: Double?) -> String {
        guard let fraction else { return missingValue }
        return "\(Int((fraction * 100).rounded()))%"
    }

    /// «55°» — для меню-бара и поповера.
    static func shortTemperature(_ celsius: Double?) -> String {
        guard let celsius else { return missingValue }
        return "\(Int(celsius.rounded()))°"
    }

    /// «55 °C» — для сводки; всегда в Цельсиях.
    static func fullTemperature(_ celsius: Double?) -> String {
        guard let celsius else { return missingValue }
        return Measurement(value: celsius, unit: UnitTemperature.celsius).formatted(
            .measurement(width: .narrow, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0)))
        )
    }

    /// «850», «1.9k» — для узкой колонки меню-бара.
    static func shortFanSpeed(_ rpm: Double?, locale: Locale = .current) -> String {
        guard let rpm else { return missingValue }
        guard rpm >= 1000 else { return "\(Int(rpm.rounded()))" }
        return (rpm / 1000).formatted(.number.precision(.fractionLength(1)).locale(locale)) + "k"
    }

    /// «1 850» — полное число оборотов.
    static func fullFanSpeed(_ rpm: Double) -> String {
        Int(rpm.rounded()).formatted(.number)
    }

    /// «4.2W», «15W» — для узкой колонки меню-бара.
    static func shortPower(_ watts: Double?, locale: Locale = .current) -> String {
        guard let watts else { return missingValue }
        return watts.formatted(.number.precision(.fractionLength(watts < 10 ? 1 : 0)).locale(locale)) + "W"
    }

    /// «4.2 W» — для поповера и сводки.
    static func fullPower(_ watts: Double?) -> String {
        guard let watts else { return missingValue }
        return Measurement(value: watts, unit: UnitPower.watts).formatted(
            .measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(1)))
        )
    }

    /// «12,4 ГБ».
    static func memorySize(_ bytes: UInt64) -> String {
        Int64(clamping: bytes).formatted(.byteCount(style: .memory))
    }
}
