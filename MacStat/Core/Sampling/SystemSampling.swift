//
//  SystemSampling.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

/// Источник замеров системы.
nonisolated protocol SystemSampling: Sendable {
    /// Делает один замер всех метрик.
    func processRows(reset: Bool) async -> [ProcessRow]
    func historyPoints(hours: Int) async -> [SystemMetric: [HistoryPoint]]
    func recordThermal(_ state: ThermalStatus) async
    func flushHistory() async -> Bool
    func takeSnapshot() async -> SystemSnapshot
}

nonisolated extension SystemSampling {
    func processRows(reset: Bool) async -> [ProcessRow] { [] }
    func historyPoints(hours: Int) async -> [SystemMetric: [HistoryPoint]] { [:] }
    func recordThermal(_ state: ThermalStatus) async {}
    func flushHistory() async -> Bool { true }
}
