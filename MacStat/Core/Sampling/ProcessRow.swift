//
//  ProcessRow.swift
//  MacStat
//

import Foundation

/// Строка процесса или группы помощников одного приложения.
nonisolated struct ProcessRow: Identifiable, Equatable, Sendable {
    /// Путь внешнего .app либо pid для самостоятельного процесса.
    let id: String
    /// Исходное имя процесса или приложения.
    let name: String
    /// Процент одного ядра, может превышать 100; nil на первом замере.
    var cpu: Double?
    /// Суммарный физический footprint, байт.
    var memory: UInt64
}
