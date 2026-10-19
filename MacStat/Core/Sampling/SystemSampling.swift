//
//  SystemSampling.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

/// Источник замеров системы.
nonisolated protocol SystemSampling: Sendable {
    /// Делает один замер всех метрик.
    func takeSnapshot() async -> SystemSnapshot
}
