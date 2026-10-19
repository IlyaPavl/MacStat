//
//  PopoverView.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

/// Окно, открывающееся по клику на значок.
struct PopoverView: View {
    /// Расстояние между карточками.
    private static let cardSpacing: CGFloat = 8

    /// Модель мониторинга.
    @Environment(MonitorViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PopoverHeader(chipName: viewModel.chipName)
            GlassEffectContainer(spacing: Self.cardSpacing) {
                Grid(horizontalSpacing: Self.cardSpacing, verticalSpacing: Self.cardSpacing) {
                    ForEach(cardRows, id: \.self) { row in
                        GridRow {
                            ForEach(row) { metric in
                                MetricCard(
                                    metric: metric,
                                    value: metric.valueText(in: viewModel.snapshot),
                                    detail: metric.detailText(in: viewModel.snapshot),
                                    history: viewModel.history(for: metric)
                                )
                                .gridCellColumns(row.count == 1 ? 2 : 1)
                            }
                        }
                    }
                }
            }
            PopoverFooter()
        }
        .padding(12)
        .frame(width: 340)
        .onAppear(perform: viewModel.popoverDidAppear)
        .onDisappear(perform: viewModel.popoverDidDisappear)
    }

    /// Карточки по две в строке; вентилятор скрыт на Mac без него.
    private var cardRows: [[SystemMetric]] {
        let metrics = SystemMetric.popoverOrder.filter { $0 != .fanSpeed || viewModel.snapshot.fanSpeed != nil }
        return stride(from: 0, to: metrics.count, by: 2).map { Array(metrics[$0..<min($0 + 2, metrics.count)]) }
    }
}
