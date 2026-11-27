//
//  PopoverView.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import AppKit
import SwiftUI

/// Окно, открывающееся по клику на значок.
struct PopoverView: View {
    /// Расстояние между карточками.
    private static let cardSpacing: CGFloat = 8
    /// Внешний отступ панели; внутри прокрутки он оставляет место теням.
    private static let contentInset: CGFloat = 12

    /// Модель мониторинга.
    @Environment(MonitorViewModel.self) private var viewModel
    /// Высота шапки.
    @State private var headerHeight: CGFloat = 0
    /// Высота прокручиваемого содержимого вместе с подвалом.
    @State private var scrollHeight: CGFloat = 0

    /// Доступные периоды графиков, часы.
    private static let historyRanges = [1, 6, 24, 48]

    var body: some View {
        // Шапка стоит над прокруткой, а не в safeAreaBar: под верхней панелью окно меню-бара
        // всегда рисует жёсткую границу.
        VStack(spacing: 0) {
            header
                .onGeometryChange(for: CGFloat.self, of: \.size.height) { headerHeight = $0 }
            scrollContent
        }
        .frame(width: 340, height: min(headerHeight + scrollHeight, maxPanelHeight))
        .onAppear(perform: viewModel.popoverDidAppear)
        .onDisappear(perform: viewModel.popoverDidDisappear)
    }

    /// Карточки, бейдж, батарея и процессы с подвалом.
    private var scrollContent: some View {
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
                                        chartEnd: viewModel.chartEnd,
                                        isWide: row.count == 1,
                                        memoryUsage: metric == .memory ? viewModel.snapshot.memoryUsage : nil
                                    )
                                    .gridCellColumns(row.count == 1 ? 2 : 1)
                                }
                            }
                        }
                    }
                }
                ThermalBadge(state: viewModel.thermalState)
                if let battery = viewModel.snapshot.battery, !battery.isEmpty {
                    BatteryDetailsView(reading: battery)
                }
                ProcessListView(top: viewModel.processes)
            }
            // Отступ внутри прокрутки оставляет место теням стекла, чтобы их не срезал край области.
            .padding(.horizontal, Self.contentInset)
            .padding(.vertical, Self.contentInset / 2)
        }
        .scrollIndicators(.hidden)
        // Панель подгоняется под содержимое, и без этого прокрутка не пружинит, когда всё помещается.
        .scrollBounceBehavior(.always, axes: .vertical)
        // Под подвал содержимое уходит с системным мягким размытием.
        .scrollEdgeEffectStyle(.soft, for: .vertical)
        .safeAreaBar(edge: .bottom) {
            PopoverFooter()
                .padding([.horizontal, .bottom], Self.contentInset)
                .padding(.top, Self.contentInset / 2)
        }
        // Окно меню-бара подгоняется под содержимое, а у ScrollView нет своей высоты,
        // поэтому высота панели задаётся явно: по содержимому с подвалом, но не выше экрана.
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentSize.height + geometry.contentInsets.top + geometry.contentInsets.bottom
        } action: { _, height in
            scrollHeight = height
        }
    }

    /// Заголовок и переключатель периода.
    private var header: some View {
        @Bindable var monitor = viewModel
        return VStack(alignment: .leading, spacing: 12) {
            PopoverHeader(chipName: viewModel.chipName)
            Picker("History range", selection: $monitor.historyHours) {
                ForEach(Self.historyRanges, id: \.self) { hours in
                    Text(verbatim: Duration.seconds(hours * 3600).formatted(.units(allowed: [.hours], width: .narrow)))
                        .tag(hours)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: .infinity)
        }
        .padding([.horizontal, .top], Self.contentInset)
        .padding(.bottom, Self.contentInset / 2)
    }

    /// Панель не должна выходить за видимую область небольшого экрана.
    private var maxPanelHeight: CGFloat {
        min(780, max(400, (NSScreen.main?.visibleFrame.height ?? 900) - 40))
    }

    /// Карточки по две в строке; метрики, которых нет на этом Mac, скрыты.
    private var cardRows: [[SystemMetric]] {
        let metrics = SystemMetric.popoverOrder.filter { !$0.dependsOnHardware || $0.value(in: viewModel.snapshot) != nil }
        return stride(from: 0, to: metrics.count, by: 2).map { Array(metrics[$0..<min($0 + 2, metrics.count)]) }
    }
}
