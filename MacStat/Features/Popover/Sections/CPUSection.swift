//
//  CPUSection.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

/// Секция процессора: загрузка, температура, вентилятор.
struct CPUSection: View {
    /// Модель мониторинга.
    @Environment(MonitorViewModel.self) private var viewModel

    var body: some View {
        let snapshot = viewModel.snapshot
        MetricSection(title: "Processor", symbolName: MenuBarMetric.cpuLoad.symbolName) {
            if let fanSpeed = snapshot.fanSpeed {
                Label("\(MetricFormatter.fullFanSpeed(fanSpeed)) rpm", systemImage: MenuBarMetric.fanSpeed.symbolName)
                    .monospacedDigit()
            }
        } value: {
            HStack {
                Text(verbatim: MetricFormatter.percent(snapshot.cpuLoad))
                Spacer()
                TemperatureLabel(celsius: snapshot.cpuTemperature)
            }
        } detail: {
            SparklineView(history: viewModel.cpuLoadHistory, tint: .blue, fixedYRange: 0...1)
        }
    }
}
