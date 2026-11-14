//
//  PopoverView.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import AppKit
import SwiftUI

/// Окно, открывающееся по клику на значок; действия остаются видимыми при прокрутке.
struct PopoverView: View {
    /// Расстояние между карточками.
    private static let cardSpacing: CGFloat = 8
    /// Модель мониторинга.
    @Environment(MonitorViewModel.self) private var viewModel

    var body: some View {
        @Bindable var monitor = viewModel
        VStack(alignment: .leading, spacing: 12) {
            PopoverHeader(chipName: viewModel.chipName)
            Picker("History range", selection: $monitor.historyHours) {
                Text("1 h").tag(1)
                Text("6 h").tag(6)
                Text("24 h").tag(24)
                Text("48 h").tag(48)
            }
            .pickerStyle(.segmented)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    GlassEffectContainer(spacing: Self.cardSpacing) {
                        Grid(horizontalSpacing: Self.cardSpacing, verticalSpacing: Self.cardSpacing) {
                            ForEach(cardRows, id: \.self) { row in
                                GridRow {
                                    ForEach(row) { metric in
                                        MetricCard(
                                            metric: metric,
                                            value: metric.valueText(in: viewModel.snapshot),
                                            detail: metric.detailText(in: viewModel.snapshot),
                                            points: viewModel.chartPoints[metric] ?? [],
                                            hours: viewModel.historyHours,
                                            memoryUsage: metric == .memory ? viewModel.snapshot.memoryUsage : nil
                                        )
                                        .gridCellColumns(row.count == 1 ? 2 : 1)
                                    }
                                }
                            }
                        }
                    }
                    DiagnosticsView()
                }
                .padding(.vertical, 2)
            }
            PopoverFooter()
        }
        .padding(12)
        .frame(width: 340, height: panelHeight)
        .onAppear(perform: viewModel.popoverDidAppear)
        .onDisappear(perform: viewModel.popoverDidDisappear)
    }

    /// Панель помещается в рабочую область небольшого экрана.
    private var panelHeight: CGFloat {
        min(650, max(300, (NSScreen.main?.visibleFrame.height ?? 800) - 80))
    }

    /// Карточки по две в строке; метрики, которых нет на этом Mac, скрыты.
    private var cardRows: [[SystemMetric]] {
        let metrics = SystemMetric.popoverOrder.filter { !$0.dependsOnHardware || $0.value(in: viewModel.snapshot) != nil }
        return stride(from: 0, to: metrics.count, by: 2).map { Array(metrics[$0..<min($0 + 2, metrics.count)]) }
    }
}
