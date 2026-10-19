//
//  MetricLabel.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

/// Название метрики с иконкой.
struct MetricLabel: View {
    /// Метрика.
    let metric: SystemMetric

    var body: some View {
        Label {
            Text(metric.title)
        } icon: {
            Image(systemName: metric.symbolName)
        }
    }
}
