//
//  UpdateInterval.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Foundation

/// Интервал между замерами.
enum UpdateInterval: Int, CaseIterable, Identifiable {
    /// 1 секунда.
    case oneSecond = 1
    /// 2 секунды.
    case twoSeconds = 2
    /// 5 секунд.
    case fiveSeconds = 5

    /// Идентификатор для `ForEach`.
    var id: Self { self }

    /// Подпись, например «2 с».
    var title: LocalizedStringResource {
        "\(rawValue) s"
    }

    /// Интервал для `Task.sleep`.
    var duration: Duration {
        .seconds(rawValue)
    }
}
