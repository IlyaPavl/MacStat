//
//  MemoryPressure.swift
//  MacStat
//
//  Created by Ilya Pavlov on 27.11.2026.
//

import Foundation

/// Системный уровень давления на память: значения `kern.memorystatus_vm_pressure_level`.
nonisolated enum MemoryPressure: Int, Sendable {
    case normal = 1
    case warning = 2
    case critical = 4

    /// Подпись для интерфейса.
    var title: LocalizedStringResource {
        switch self {
        case .normal: "Memory pressure: normal"
        case .warning: "Memory pressure: warning"
        case .critical: "Memory pressure: critical"
        }
    }
}
