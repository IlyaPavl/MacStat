//
//  SparklineView.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Charts
import SwiftUI

/// График по реальному времени: отдельные сегменты для пропусков и пунктирные пики температур.
struct SparklineView: View {
    let points: [HistoryPoint]
    let hours: Int
    let tint: Color
    let baseRange: ClosedRange<Double>
    let showPeaks: Bool
    let axisLabel: (Double) -> String

    var body: some View {
        let now = Date()
        let range = yRange
        Chart(points) { point in
            LineMark(
                x: .value("Time", point.date),
                y: .value("Average", point.value),
                series: .value("Segment", "average-\(point.segment)")
            )
            .foregroundStyle(tint)
            .lineStyle(StrokeStyle(lineWidth: 1.5))

            PointMark(x: .value("Time", point.date), y: .value("Average", point.value))
                .foregroundStyle(tint)
                .symbolSize(3)

            if showPeaks {
                PointMark(x: .value("Time", point.date), y: .value("Peak", point.peak))
                    .foregroundStyle(tint.opacity(0.5))
                    .symbolSize(3)
                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Peak", point.peak),
                    series: .value("Segment", "peak-\(point.segment)")
                )
                .foregroundStyle(tint.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
            }
        }
        .chartXScale(domain: now.addingTimeInterval(-Double(hours) * 3600)...now)
        .chartYScale(domain: range)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 2)) { _ in
                AxisValueLabel(format: .dateTime.hour().minute())
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: [range.lowerBound, range.upperBound]) { mark in
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
        .accessibilityLabel(Text("History"))
    }

    /// Сохраняет базовую шкалу и расширяет её при значениях выше диапазона.
    private var yRange: ClosedRange<Double> {
        let high = points.map { showPeaks ? $0.peak : $0.value }.max() ?? baseRange.upperBound
        let step = (baseRange.upperBound - baseRange.lowerBound) / 2
        guard high > baseRange.upperBound, step > 0 else { return baseRange }
        return baseRange.lowerBound...((high / step).rounded(.up) * step)
    }
}
