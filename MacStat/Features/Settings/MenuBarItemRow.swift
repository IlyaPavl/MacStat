//
//  MenuBarItemRow.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

/// Строка элемента меню-бара: метрика, вторая строка столбца и действия.
struct MenuBarItemRow: View {
    /// Настройки — для перемещения и удаления.
    @Environment(AppSettings.self) private var settings
    /// Редактируемый элемент.
    @Binding var item: MenuBarItem

    var body: some View {
        HStack {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)

            Picker("Metric", selection: $item.primary) {
                ForEach(SystemMetric.allCases) { metric in
                    MetricLabel(metric: metric).tag(metric)
                }
            }

            Picker("Second row", selection: $item.secondary) {
                Text("Single row").tag(SystemMetric?.none)
                Divider()
                ForEach(SystemMetric.allCases) { metric in
                    MetricLabel(metric: metric).tag(Optional(metric))
                }
            }

            Menu {
                Button("Move up", systemImage: "arrow.up") {
                    settings.moveMenuBarItem(item, by: -1)
                }
                .disabled(!settings.canMoveMenuBarItem(item, by: -1))

                Button("Move down", systemImage: "arrow.down") {
                    settings.moveMenuBarItem(item, by: 1)
                }
                .disabled(!settings.canMoveMenuBarItem(item, by: 1))

                Divider()

                Button("Remove", systemImage: "trash", role: .destructive) {
                    settings.removeMenuBarItem(item)
                }
            } label: {
                Label("Actions", systemImage: "ellipsis")
                    .labelStyle(.iconOnly)
            }
            .menuIndicator(.hidden)
            .buttonStyle(.borderless)
            .fixedSize()
        }
        .labelsHidden()
    }
}
