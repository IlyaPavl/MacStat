//
//  BatteryReading.swift
//  MacStat
//

import Foundation

/// Доступные сведения о батарее; отсутствующие свойства не подменяются нулями.
nonisolated struct BatteryReading: Equatable, Sendable {
    /// Число полных циклов заряда.
    var cycles: Int?
    /// Полная ёмкость относительно проектной, в процентах.
    var health: Double?
    /// Мощность батареи, Вт; отрицательная при разряде.
    var watts: Double?
    /// Номинальная мощность подключённого адаптера, Вт.
    var adapterWatts: Double?
    /// Подключено ли внешнее питание; nil при неизвестном значении.
    var external: Bool?
    /// Идёт ли зарядка; nil при неизвестном значении.
    var charging: Bool?

    /// Отношение сырой полной ёмкости к проектной, в процентах.
    static func health(maximum: Double?, design: Double?) -> Double? {
        guard let maximum, let design,
              maximum.isFinite, design.isFinite, maximum > 0, design > 0 else { return nil }
        return maximum / design * 100
    }

    /// Ватты со знаком: отрицательное значение означает разряд.
    static func power(voltage: Double?, amperage: UInt64?) -> Double? {
        guard let voltage, let amperage, voltage.isFinite, voltage > 0 else { return nil }
        let signedAmperage = Int64(bitPattern: amperage)
        return voltage * Double(signedAmperage) / 1_000_000
    }
}
