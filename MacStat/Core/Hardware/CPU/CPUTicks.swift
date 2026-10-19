//
//  CPUTicks.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

/// Накопленные тики CPU по режимам.
nonisolated struct CPUTicks: Equatable, Sendable {
    /// Пользовательский код.
    var user: UInt32
    /// Ядро системы.
    var system: UInt32
    /// Простой.
    var idle: UInt32
    /// Процессы с пониженным приоритетом.
    var nice: UInt32

    /// Доля занятого времени 0...1 между двумя замерами; учитывает переполнение счётчиков.
    static func busyFraction(from old: CPUTicks, to new: CPUTicks) -> Double? {
        let busy = Double((new.user &- old.user) &+ (new.system &- old.system) &+ (new.nice &- old.nice))
        let idle = Double(new.idle &- old.idle)
        let total = busy + idle
        return total > 0 ? busy / total : nil
    }
}
