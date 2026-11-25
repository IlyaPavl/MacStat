//
//  ProcessCPU.swift
//  MacStat
//
//  Created by Ilya Pavlov on 27.11.2026.
//

import Foundation

/// Чистые вычисления для чтения процессов; отделены от libproc ради тестов.
nonisolated enum ProcessCPU {
    /// Процент одного ядра по приросту CPU-времени в тиках mach.
    /// Тики переводятся в наносекунды через `numer/denom`: на Apple Silicon это 125/3, а не 1/1.
    static func percent(before: UInt64, after: UInt64, elapsed: TimeInterval, numer: UInt32, denom: UInt32) -> Double? {
        guard after >= before, elapsed > 0, numer > 0, denom > 0 else { return nil }
        let nanoseconds = Double(after - before) * Double(numer) / Double(denom)
        return nanoseconds / 1_000_000_000 / elapsed * 100
    }

    /// Внешний `.app` для помощников вроде «Google Chrome Helper»; `nil` для процессов вне приложений.
    static func applicationPath(in executablePath: String) -> String? {
        guard let range = executablePath.range(of: ".app/") else { return nil }
        return String(executablePath[..<range.lowerBound]) + ".app"
    }
}
