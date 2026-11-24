//
//  BatteryReading.swift
//  MacStat
//
//  Created by Ilya Pavlov on 27.11.2026.
//

import Foundation

/// Сведения о батарее; отсутствующие свойства остаются `nil`, а не подменяются нулями.
nonisolated struct BatteryReading: Equatable, Sendable {
    /// Число циклов заряда.
    var cycles: Int?
    /// Полная ёмкость относительно проектной, %.
    var health: Double?
    /// Мощность батареи, Вт; отрицательная при разряде.
    var watts: Double?
    /// Мощность подключённого адаптера, Вт.
    var adapterWatts: Double?
    /// Подключено ли внешнее питание.
    var isExternalPowerConnected: Bool?
    /// Идёт ли зарядка.
    var isCharging: Bool?

    /// Нечего показывать: блок батареи скрывается целиком.
    var isEmpty: Bool {
        self == BatteryReading()
    }

    /// `AppleRawMaxCapacity / DesignCapacity` в процентах; обе величины в мА·ч.
    static func health(maximum: Double?, design: Double?) -> Double? {
        guard let maximum, let design, maximum > 0, design > 0 else { return nil }
        return maximum / design * 100
    }

    /// Мощность в ваттах: мВ × мА / 1e6. Ток приходит как беззнаковое число, поэтому читается как знаковое.
    static func power(voltage: Double?, amperage: UInt64?) -> Double? {
        guard let voltage, let amperage, voltage > 0 else { return nil }
        return voltage * Double(Int64(bitPattern: amperage)) / 1_000_000
    }
}
