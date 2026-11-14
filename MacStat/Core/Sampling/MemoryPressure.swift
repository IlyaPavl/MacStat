//
//  MemoryPressure.swift
//  MacStat
//

import Foundation

/// Дискретный системный уровень давления памяти, без искусственного процента.
nonisolated enum MemoryPressure: Int, Sendable {
    case normal = 1
    case warning = 2
    case critical = 4

    /// Подпись уровня давления памяти.
    var title: LocalizedStringResource {
        switch self {
        case .normal: "Memory pressure: normal"
        case .warning: "Memory pressure: warning"
        case .critical: "Memory pressure: critical"
        }
    }
}
