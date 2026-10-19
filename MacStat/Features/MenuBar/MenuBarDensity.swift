//
//  MenuBarDensity.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import CoreGraphics
import Foundation

/// Плотность значка: расстояния между элементами.
enum MenuBarDensity: String, CaseIterable, Identifiable {
    /// Минимальные отступы.
    case compact
    /// Обычные отступы.
    case standard

    /// Идентификатор для `ForEach`.
    var id: Self { self }

    /// Название в настройках.
    var title: LocalizedStringResource {
        switch self {
        case .compact: "Compact"
        case .standard: "Standard"
        }
    }

    /// Отступ между колонками в двухстрочном стиле.
    var columnSpacing: CGFloat {
        switch self {
        case .compact: 3
        case .standard: 7
        }
    }

    /// Отступ между метриками в стиле «иконки и значения».
    var itemSpacing: CGFloat {
        switch self {
        case .compact: 4
        case .standard: 8
        }
    }

    /// Отступ между иконкой и значением.
    var iconTextSpacing: CGFloat {
        switch self {
        case .compact: 1
        case .standard: 2
        }
    }
}
