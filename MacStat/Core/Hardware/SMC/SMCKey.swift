//
//  SMCKey.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

/// Четырёхсимвольный ключ SMC, например «TC0P».
nonisolated struct SMCKey: Hashable, Sendable {
    /// Ключ как число big-endian.
    let code: UInt32

    /// Ключ из готового кода.
    init(code: UInt32) {
        self.code = code
    }

    /// Ключ из строки (берутся первые 4 символа).
    init(_ name: String) {
        code = name.utf8.prefix(4).reduce(0) { $0 << 8 | UInt32($1) }
    }

    /// Ключ строкой.
    var name: String {
        String(decoding: [24, 16, 8, 0].map { UInt8(truncatingIfNeeded: code >> $0) }, as: UTF8.self)
    }
}
