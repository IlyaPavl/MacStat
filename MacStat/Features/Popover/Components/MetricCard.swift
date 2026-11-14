//
//  MetricCard.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

/// Стеклянная карточка метрики: название, значение и график.
struct MetricCard: View {
    /// Метрика.
    let metric: SystemMetric
    /// Крупное значение.
    let value: Text
    /// Уточнение справа от значения.
    let detail: Text?
    /// Данные графика.
    let history: MetricHistory

    var points: [HistoryPoint] = []
    var hours: Int = 1
    var memoryUsage: MemoryUsage? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(metric.title)
            } icon: {
                Image(systemName: metric.symbolName)
                    .foregroundStyle(metric.tint)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)

            if let memoryUsage { MemoryDetailsView(usage: memoryUsage) }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                value
                    .font(metric == .memory ? .caption : .title3.weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let detail {
                    Spacer(minLength: 0)
                    detail
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            TimelineSparkline(points: points, hours: hours, tint: metric.tint, baseRange: metric.chartRange, showPeaks: metric == .cpuTemperature || metric == .gpuTemperature || metric == .batteryTemperature)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.interactive().tint(metric.tint.opacity(0.12)), in: .rect(cornerRadius: 16))
    }
}
