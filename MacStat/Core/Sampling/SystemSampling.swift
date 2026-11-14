//
//  SystemSampling.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

/// Источник замеров и истории; все операции выполняет один актор.
nonisolated protocol SystemSampling: Sendable {
    /// Делает один замер всех метрик и добавляет его в историю.
    func takeSnapshot() async -> SystemSnapshot
    /// Читает процессы; вызывается только при открытой панели.
    func sampleProcesses() async -> [ProcessRow]
    /// Сбрасывает дельты CPU при новом сеансе наблюдения.
    func resetProcesses() async
    /// Подготавливает ограниченный набор точек для выбранного периода.
    func historyPoints(hours: Int) async -> [SystemMetric: [HistoryPoint]]
    /// Добавляет событие смены теплового состояния.
    func recordThermal(_ state: ThermalStatus) async
    /// Сохраняет историю при сне и нормальном завершении приложения.
    func flushHistory() async -> Bool
}
