//
//  MemoryUsage.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

/// Использование оперативной памяти.
nonisolated struct MemoryUsage: Equatable, Sendable {
    /// Занято, байт.
    let usedBytes: UInt64
    /// Всего, байт.
    let totalBytes: UInt64
    /// Уровень давления на память; `nil`, если sysctl недоступен.
    var pressure: MemoryPressure? = nil
    /// Занято в swap, байт.
    var swapBytes: UInt64? = nil
    /// Размер сжатых страниц, байт.
    var compressedBytes: UInt64? = nil

    /// Доля занятой памяти 0...1.
    var usedFraction: Double {
        totalBytes > 0 ? Double(usedBytes) / Double(totalBytes) : 0
    }
}
