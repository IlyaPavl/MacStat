//
//  TopProcesses.swift
//  MacStat
//
//  Created by Ilya Pavlov on 27.11.2026.
//

import Foundation

/// Самые нагружающие приложения по CPU и по памяти. Отбирается вне главного потока.
nonisolated struct TopProcesses: Equatable, Sendable {
    /// По загрузке CPU; пусто, пока CPU ещё не измерен.
    var cpu: [ProcessRow] = []
    /// По физической памяти.
    var memory: [ProcessRow] = []

    /// Ещё ни одного обхода.
    static let empty = TopProcesses()

    /// Отбирает `limit` строк каждого списка. При равных значениях порядок по `id`, чтобы строки не прыгали.
    init(rows: [ProcessRow], limit: Int = 3) {
        cpu = Array(
            rows.compactMap { row in row.cpu.map { (row, $0) } }
                .sorted { ($0.1, $1.0.id) > ($1.1, $0.0.id) }
                .prefix(limit)
                .map(\.0)
        )
        memory = Array(rows.sorted { ($0.memory, $1.id) > ($1.memory, $0.id) }.prefix(limit))
    }

    /// Пустой результат.
    private init() {}
}
