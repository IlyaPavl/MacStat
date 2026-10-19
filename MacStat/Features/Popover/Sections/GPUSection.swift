//
//  GPUSection.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

/// Секция графики: температура и график.
struct GPUSection: View {
    /// Модель мониторинга.
    @Environment(MonitorViewModel.self) private var viewModel

    var body: some View {
        MetricSection(title: "Graphics", symbolName: MenuBarMetric.gpuTemperature.symbolName) {
            Text("Average across sensors")
        } value: {
            TemperatureLabel(celsius: viewModel.snapshot.gpuTemperature)
        } detail: {
            SparklineView(history: viewModel.gpuTemperatureHistory, tint: .orange)
        }
    }
}
