//
//  ThermalBadge.swift
//  MacStat
//
//  Created by Ilya Pavlov on 27.11.2026.
//

import SwiftUI

/// Тепловое состояние macOS. Само по себе не доказывает, что частоты снижены.
struct ThermalBadge: View {
    /// Состояние системы.
    let state: ProcessInfo.ThermalState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label {
                Text("Thermal state: \(String(localized: state.title))")
            } icon: {
                Image(systemName: "thermometer.medium")
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(state.tint.opacity(0.18), in: .capsule)
            Text("macOS heat signal. It does not mean the clock speed is already reduced.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
