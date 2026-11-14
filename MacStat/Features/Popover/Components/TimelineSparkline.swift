import Charts
import SwiftUI

struct TimelineSparkline: View {
    let points: [HistoryPoint]
    let hours: Int
    let tint: Color
    let baseRange: ClosedRange<Double>
    let showPeaks: Bool
    var body: some View {
        let now = Date()
        let high = max(baseRange.upperBound, points.map { showPeaks ? $0.peak : $0.value }.max() ?? baseRange.upperBound)
        Chart(points) { point in
            LineMark(x: .value("Time", point.date), y: .value("Average", point.value), series: .value("Segment", "avg-\(point.segment)"))
                .foregroundStyle(tint).lineStyle(StrokeStyle(lineWidth: 1.5))
            if showPeaks {
                LineMark(x: .value("Time", point.date), y: .value("Peak", point.peak), series: .value("Segment", "peak-\(point.segment)"))
                    .foregroundStyle(tint.opacity(0.5)).lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
            }
        }
        .chartXScale(domain: now.addingTimeInterval(-Double(hours) * 3600)...now)
        .chartYScale(domain: baseRange.lowerBound...high)
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 2)) { _ in AxisValueLabel(format: .dateTime.hour().minute()) } }
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .frame(height: 56)
        .accessibilityLabel(Text("History"))
    }
}
