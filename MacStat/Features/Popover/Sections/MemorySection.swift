//
//  MemorySection.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

/// Секция памяти: процент, объём и полоса заполнения.
struct MemorySection: View {
    /// Модель мониторинга.
    @Environment(MonitorViewModel.self) private var viewModel

    var body: some View {
        let memoryUsage = viewModel.snapshot.memoryUsage
        MetricSection(title: "Memory", symbolName: MenuBarMetric.memory.symbolName) {
            if let memoryUsage {
                Text("\(MetricFormatter.memorySize(memoryUsage.usedBytes)) of \(MetricFormatter.memorySize(memoryUsage.totalBytes))")
                    .monospacedDigit()
            }
        } value: {
            Text(verbatim: MetricFormatter.percent(memoryUsage?.usedFraction))
        } detail: {
            ProgressView(value: memoryUsage?.usedFraction ?? 0)
                .progressViewStyle(.linear)
                .tint(.purple)
        }
    }
}
