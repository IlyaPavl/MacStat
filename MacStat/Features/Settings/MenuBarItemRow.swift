//
//  MenuBarItemRow.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

/// Строка элемента меню-бара: метрика, переключатель столбца и нижняя метрика.
struct MenuBarItemRow: View {
    /// Настройки — для удаления.
    @Environment(AppSettings.self) private var settings
    /// Редактируемый элемент.
    @Binding var item: MenuBarItem

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)

                MetricPicker(title: "Metric", selection: $item.primary)

                Spacer()

                Toggle("Stacked", isOn: $item.isStacked.animation())
                    .toggleStyle(.switch)
                    .controlSize(.small)

                Button("Remove", systemImage: "minus.circle", role: .destructive) {
                    settings.removeMenuBarItem(item)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
            }

            if let secondary = item.secondary {
                HStack {
                    Image(systemName: "arrow.turn.down.right")
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                    MetricPicker(title: "Bottom", selection: Binding {
                        secondary
                    } set: {
                        item.secondary = $0
                    })
                }
                .padding(.leading, 20)
            }
        }
    }
}

/// Выбор метрики из всех без видимой подписи.
private struct MetricPicker: View {
    /// Подпись для VoiceOver.
    let title: LocalizedStringResource
    /// Выбранная метрика.
    @Binding var selection: SystemMetric

    var body: some View {
        Picker(selection: $selection) {
            ForEach(SystemMetric.allCases) { metric in
                MetricLabel(metric: metric).tag(metric)
            }
        } label: {
            Text(title)
        }
        .labelsHidden()
        .fixedSize()
    }
}
