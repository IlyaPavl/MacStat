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
    /// Точки графика за выбранный период.
    let points: [HistoryPoint]
    /// Период графика в часах.
    let hours: Int
    /// Момент последнего обновления точек.
    let chartEnd: Date
    /// Карточка на всю ширину панели.
    var isWide = false
    /// Давление памяти и swap; только для карточки памяти.
    var memoryUsage: MemoryUsage?

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

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                value
                    .font(.title3.weight(.semibold))
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

            if let memoryUsage {
                MemoryDetailsView(usage: memoryUsage)
            }

            SparklineView(
                metric: metric,
                points: points,
                hours: hours,
                end: chartEnd,
                isWide: isWide,
                tint: metric.tint,
                baseRange: metric.chartRange,
                showsPeaks: metric.showsHistoryPeaks && hours > 1
            )
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(metric.tint.opacity(0.12)), in: .rect(cornerRadius: 16))
    }
}
