//
//  SparklineView.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Charts
import SwiftUI

/// Мини-график истории метрики.
struct SparklineView: View {
    /// Данные графика.
    let history: MetricHistory
    /// Цвет линии и заливки.
    let tint: Color
    /// Фиксированный диапазон по Y (например, 0...1); `nil` — по данным с запасом.
    var fixedYRange: ClosedRange<Double>?

    var body: some View {
        let values = history.values
        let yRange = yRange
        Chart(values.indices, id: \.self) { index in
            AreaMark(
                x: .value("Sample", index),
                yStart: .value("Floor", yRange.lowerBound),
                yEnd: .value("Value", values[index])
            )
            .foregroundStyle(tint.opacity(0.12))
            .interpolationMethod(.monotone)

            LineMark(x: .value("Sample", index), y: .value("Value", values[index]))
                .foregroundStyle(tint)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .interpolationMethod(.monotone)
        }
        .chartXScale(domain: 0...(history.capacity - 1))
        .chartYScale(domain: yRange)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .frame(height: 32)
        .accessibilityHidden(true)
    }

    /// Итоговый диапазон по Y.
    private var yRange: ClosedRange<Double> {
        if let fixedYRange { return fixedYRange }
        guard let low = history.values.min(), let high = history.values.max() else { return 0...1 }
        return (low - 3)...(high + 3)
    }
}
