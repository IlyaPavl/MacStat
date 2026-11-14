//
//  ThermalBadge.swift
//  MacStat
//

import SwiftUI

/// Цветной бейдж теплового состояния macOS.
struct ThermalBadge: View {
    let state: ThermalStatus

    var body: some View {
        Label {
            Text("Thermal state: \(String(localized: state.title))")
        } icon: {
            Image(systemName: "thermometer.medium")
        }
        .font(.caption.weight(.medium))
        .padding(6)
        .background(tint.opacity(0.15), in: .capsule)
    }

    /// Цвет дополняет текст, поэтому состояние читается и без различения цветов.
    private var tint: Color {
        switch state {
        case .normal: .green
        case .elevated: .yellow
        case .high: .orange
        case .critical: .red
        }
    }
}
