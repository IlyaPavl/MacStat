//
//  ProcessRow.swift
//  MacStat
//
//  Created by Ilya Pavlov on 27.11.2026.
//

import Foundation

/// Процесс или приложение со всеми его помощниками.
nonisolated struct ProcessRow: Identifiable, Equatable, Sendable {
    /// Путь к `.app` либо `pid:N` для процесса вне приложения.
    let id: String
    /// Название для интерфейса.
    let name: String
    /// Загрузка в процентах одного ядра, может превышать 100; `nil` на первом замере.
    var cpu: Double?
    /// Физическая память (footprint), байт.
    var memory: UInt64
}
