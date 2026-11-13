//
//  SparklineView.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Charts
import SwiftUI

/// Мини-график истории метрики с осью значений.
struct SparklineView: View {
    /// Данные графика.
    let history: MetricHistory
    /// Цвет линии и заливки.
    let tint: Color
    /// Базовый диапазон по Y; верхняя граница растёт шагами в половину диапазона, если значения выходят за неё.
    let baseRange: ClosedRange<Double>
    /// Подпись деления оси.
    let axisLabel: (Double) -> String

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
        .chartYAxis {
            let ticks = [yRange.lowerBound, (yRange.lowerBound + yRange.upperBound) / 2, yRange.upperBound]
            AxisMarks(position: .trailing, values: ticks) { mark in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                AxisValueLabel {
                    if let value = mark.as(Double.self) {
                        Text(verbatim: axisLabel(value))
                            .font(.system(size: 8))
                            .monospacedDigit()
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .frame(height: 56)
        .accessibilityHidden(true)
    }

    /// Итоговый диапазон по Y.
    private var yRange: ClosedRange<Double> {
        let step = (baseRange.upperBound - baseRange.lowerBound) / 2
        guard let high = history.values.max(), high > baseRange.upperBound, step > 0 else { return baseRange }
        return baseRange.lowerBound...((high / step).rounded(.up) * step)
    }
}
