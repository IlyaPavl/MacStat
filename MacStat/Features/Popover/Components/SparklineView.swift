//
//  SparklineView.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Charts
import SwiftUI

/// График метрики по реальному времени. Паузы (сон, выключение) разрывают линию, а не соединяются ложной.
/// Все входы сравнимы, поэтому график перерисовывается только при обновлении точек, а не на каждый замер.
struct SparklineView: View, Equatable {
    /// Метрика: задаёт подписи оси.
    let metric: SystemMetric
    /// Точки графика.
    let points: [HistoryPoint]
    /// Период графика в часах.
    let hours: Int
    /// Правый край оси времени — момент последнего обновления точек.
    let end: Date
    /// Широкий график: помещается подпись середины периода.
    let isWide: Bool
    /// Цвет линии и заливки.
    let tint: Color
    /// Базовый диапазон по Y; верхняя граница растёт шагами в половину диапазона, если значения выходят за неё.
    let baseRange: ClosedRange<Double>
    /// Рисовать ли пунктир максимумов.
    let showsPeaks: Bool

    var body: some View {
        let yRange = yRange
        let start = end.addingTimeInterval(-Double(hours) * 3600)
        // Сегмент из одной точки не рисуется линией, поэтому показываем его маркером.
        let isolated = Set(Dictionary(grouping: points, by: \.segment).filter { $0.value.count == 1 }.keys)
        Chart(points) { point in
            AreaMark(
                x: .value("Time", point.date),
                yStart: .value("Floor", yRange.lowerBound),
                yEnd: .value("Value", point.value),
                series: .value("Segment", "area-\(point.segment)")
            )
            .foregroundStyle(tint.opacity(0.12))
            .interpolationMethod(.monotone)

            LineMark(
                x: .value("Time", point.date),
                y: .value("Value", point.value),
                series: .value("Segment", "line-\(point.segment)")
            )
            .foregroundStyle(tint)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .interpolationMethod(.monotone)

            if showsPeaks {
                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Peak", point.peak),
                    series: .value("Segment", "peak-\(point.segment)")
                )
                .foregroundStyle(tint.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
            }

            if isolated.contains(point.segment) {
                PointMark(x: .value("Time", point.date), y: .value("Value", point.value))
                    .foregroundStyle(tint)
                    .symbolSize(8)
            }
        }
        .chartXScale(domain: start...end)
        .chartYScale(domain: yRange)
        .chartXAxis {
            // Крайние метки прижаты внутрь графика; середина только на широком графике, в узком ей не хватает места.
            let middle = start.addingTimeInterval(Double(hours) * 1800)
            AxisMarks(values: isWide ? [start, middle, end] : [start, end]) { mark in
                AxisValueLabel(anchor: Self.xLabelAnchor(index: mark.index, count: mark.count)) {
                    if let date = mark.as(Date.self) {
                        Text(date, format: timeFormat)
                            .font(.system(size: 8))
                    }
                }
            }
        }
        .chartYAxis {
            let ticks = [yRange.lowerBound, (yRange.lowerBound + yRange.upperBound) / 2, yRange.upperBound]
            AxisMarks(position: .trailing, values: ticks) { mark in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                AxisValueLabel {
                    if let value = mark.as(Double.self) {
                        Text(verbatim: metric.axisLabel(for: value))
                            .font(.system(size: 8))
                            .monospacedDigit()
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .frame(height: 64)
        .accessibilityHidden(true)
    }

    /// Крайние подписи выравниваются внутрь графика, средняя — по центру.
    private static func xLabelAnchor(index: Int, count: Int) -> UnitPoint {
        switch index {
        case 0: .topLeading
        case count - 1: .topTrailing
        default: .top
        }
    }

    /// Для периодов длиннее суток время без дня недели неоднозначно.
    private var timeFormat: Date.FormatStyle {
        hours > 24 ? .dateTime.weekday(.abbreviated).hour() : .dateTime.hour().minute()
    }

    /// Итоговый диапазон по Y.
    private var yRange: ClosedRange<Double> {
        let step = (baseRange.upperBound - baseRange.lowerBound) / 2
        let high = points.map { showsPeaks ? $0.peak : $0.value }.max()
        guard let high, high > baseRange.upperBound, step > 0 else { return baseRange }
        return baseRange.lowerBound...((high / step).rounded(.up) * step)
    }
}
