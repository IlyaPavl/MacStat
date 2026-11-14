//
//  ProcessCPU.swift
//  MacStat
//

import Foundation

/// Переводит дельту mach absolute time в процент одного ядра.
nonisolated enum ProcessCPU {
    /// Откат счётчика и некорректное время не дают CPU%; первый замер отсекает читатель.
    static func percent(
        before: UInt64,
        after: UInt64,
        elapsed: TimeInterval,
        numerator: UInt32,
        denominator: UInt32
    ) -> Double? {
        guard elapsed.isFinite, elapsed > 0, after >= before, numerator > 0, denominator > 0 else { return nil }
        let nanoseconds = Double(after - before) * Double(numerator) / Double(denominator)
        return nanoseconds / 1_000_000_000 / elapsed * 100
    }

    /// Для помощников вложенных бандлов выбирает внешнее приложение.
    static func applicationPath(in executablePath: String) -> String? {
        guard let range = executablePath.range(of: ".app/") else { return nil }
        return String(executablePath[..<range.lowerBound]) + ".app"
    }
}
