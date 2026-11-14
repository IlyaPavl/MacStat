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

    var pressure: MemoryPressure? = nil
    var swapBytes: UInt64? = nil
    var compressedBytes: UInt64? = nil

    /// Доля занятой памяти 0...1.
    var usedFraction: Double {
        totalBytes > 0 ? Double(usedBytes) / Double(totalBytes) : 0
    }
}
