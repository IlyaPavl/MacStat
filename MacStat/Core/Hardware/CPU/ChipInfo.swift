//
//  ChipInfo.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Darwin

/// Сведения о чипе.
nonisolated enum ChipInfo {
    /// Ключ sysctl с названием чипа.
    private static let brandKey = "machdep.cpu.brand_string"
    /// Название, если sysctl не ответил.
    private static let fallbackName = "Mac"

    /// Название чипа, например «Apple M3 Pro».
    static func marketingName() -> String {
        var size = 0
        guard sysctlbyname(brandKey, nil, &size, nil, 0) == 0, size > 0 else { return fallbackName }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(brandKey, &buffer, &size, nil, 0) == 0 else { return fallbackName }
        return String(decoding: buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }
}
