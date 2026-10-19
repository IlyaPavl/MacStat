//
//  MetricPicker.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

/// Выбор одной метрики из всех.
struct MetricPicker: View {
    /// Подпись слева.
    let title: LocalizedStringResource
    /// Выбранная метрика.
    @Binding var selection: SystemMetric

    var body: some View {
        Picker(selection: $selection) {
            ForEach(SystemMetric.allCases) { metric in
                Label {
                    Text(metric.title)
                } icon: {
                    Image(systemName: metric.symbolName)
                }
                .tag(metric)
            }
        } label: {
            Text(title)
        }
    }
}
