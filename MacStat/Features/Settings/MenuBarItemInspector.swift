//
//  MenuBarItemInspector.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

/// Настройки выбранного элемента: вид и метрики.
struct MenuBarItemInspector: View {
    /// Редактируемый элемент.
    @Binding var item: MenuBarItem

    var body: some View {
        Picker("Layout", selection: $item.isStacked.animation()) {
            Text("One metric").tag(false)
            Text("Two metrics").tag(true)
        }
        .pickerStyle(.segmented)

        MetricPicker(selection: $item.primary) {
            Text(item.isStacked ? "Top" : "Metric")
        }

        if let secondary = item.secondary {
            MetricPicker(selection: Binding {
                secondary
            } set: {
                item.secondary = $0
            }) {
                Text("Bottom")
            }
        }
    }
}

/// Выбор метрики из всех.
private struct MetricPicker<Title: View>: View {
    /// Выбранная метрика.
    @Binding var selection: SystemMetric
    /// Подпись строки.
    @ViewBuilder let title: Title

    var body: some View {
        Picker(selection: $selection) {
            ForEach(SystemMetric.allCases) { metric in
                MetricLabel(metric: metric).tag(metric)
            }
        } label: {
            title
        }
    }
}
