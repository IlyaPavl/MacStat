//
//  MemoryDetailsView.swift
//  MacStat
//
//  Created by Ilya Pavlov on 27.11.2026.
//

import SwiftUI

/// Давление на память — главный показатель; swap и сжатая память сами по себе карточку не окрашивают.
struct MemoryDetailsView: View {
    /// Использование памяти.
    let usage: MemoryUsage

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let pressure = usage.pressure {
                Label {
                    Text(pressure.title)
                } icon: {
                    Circle().fill(tint(for: pressure)).frame(width: 7, height: 7)
                }
            }
            HStack(spacing: 8) {
                if let swap = usage.swapBytes {
                    // Нулевой swap — обычное состояние: «0» без единиц и без цвета.
                    Text("Swap: \(swap == 0 ? "0" : MetricFormatter.memorySize(swap))")
                }
                if let compressed = usage.compressedBytes {
                    Text("Compressed: \(MetricFormatter.memorySize(compressed))")
                }
            }
            .foregroundStyle(.secondary)
        }
        .font(.caption2)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    /// Цвет соответствует дискретному уровню системы, а не проценту занятой памяти.
    private func tint(for pressure: MemoryPressure) -> Color {
        switch pressure {
        case .normal: .green
        case .warning: .yellow
        case .critical: .red
        }
    }
}
