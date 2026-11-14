//
//  MemoryDetailsView.swift
//  MacStat
//

import SwiftUI

/// Давление памяти — основное состояние; swap сам по себе не окрашивает карточку.
struct MemoryDetailsView: View {
    let usage: MemoryUsage

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let pressure = usage.pressure {
                RoundedRectangle(cornerRadius: 2)
                    .fill(tint(for: pressure))
                    .frame(height: 3)
                Text(pressure.title).font(.caption.weight(.medium))
            }
            if let swap = usage.swapBytes {
                Text("Swap: \(MetricFormatter.memorySize(swap))")
            }
            if let compressed = usage.compressedBytes {
                Text("Compressed: \(MetricFormatter.memorySize(compressed))")
            }
        }
        .font(.caption2)
    }

    /// Цвет соответствует дискретному уровню sysctl, а не проценту занятой RAM.
    private func tint(for pressure: MemoryPressure) -> Color {
        switch pressure {
        case .normal: .green
        case .warning: .yellow
        case .critical: .red
        }
    }
}
