//
//  SMCSensor.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

/// Датчик SMC: ключ и формат его значения.
nonisolated struct SMCSensor: Hashable, Sendable {
    /// Ключ датчика.
    let key: SMCKey
    /// Размер значения, байт.
    let dataSize: UInt32
    /// Тип значения (`flt `, `sp78` и т. п.).
    let dataType: UInt32
}
