//
//  SystemSampling.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

/// Источник замеров системы и их истории.
nonisolated protocol SystemSampling: Sendable {
    /// Делает один замер всех метрик и добавляет его в историю.
    func takeSnapshot() async -> SystemSnapshot
    /// Обходит процессы; вызывается только при открытой панели.
    func sampleProcesses() async -> TopProcesses
    /// Сбрасывает прошлый замер процессов, чтобы CPU не считался через паузу.
    func resetProcesses() async
    /// Точки графиков за выбранное число часов, уже уменьшенные для отрисовки.
    func historyPoints(hours: Int) async -> [SystemMetric: [HistoryPoint]]
}
