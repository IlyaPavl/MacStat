//
//  ThermalState+Display.swift
//  MacStat
//
//  Created by Ilya Pavlov on 27.11.2026.
//

import SwiftUI

extension ProcessInfo.ThermalState {
    /// Название состояния.
    var title: LocalizedStringResource {
        switch self {
        case .nominal: "Normal"
        case .fair: "Elevated"
        case .serious: "High"
        case .critical: "Critical"
        @unknown default: "Elevated"
        }
    }

    /// Цвет бейджа.
    var tint: Color {
        switch self {
        case .nominal: .green
        case .fair: .yellow
        case .serious: .orange
        case .critical: .red
        @unknown default: .yellow
        }
    }

    /// Значок в меню-баре нужен только при серьёзном нагреве.
    var needsWarning: Bool {
        self == .serious || self == .critical
    }
}
