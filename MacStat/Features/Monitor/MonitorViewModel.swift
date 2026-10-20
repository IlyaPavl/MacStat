//
//  MonitorViewModel.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Foundation
import Observation

/// Периодически снимает метрики и готовит их для меню-бара и поповера.
@Observable
final class MonitorViewModel {
    /// Длина истории для графиков.
    private static let historyCapacity = 60

    /// Последний замер.
    private(set) var snapshot: SystemSnapshot = .empty
    /// История значений каждой метрики для графиков.
    private(set) var histories = Dictionary(
        uniqueKeysWithValues: SystemMetric.allCases.map { ($0, MetricHistory(capacity: historyCapacity)) }
    )
    /// Элементы меню-бара со значениями; меняются только при изменении текста.
    private(set) var menuBarColumns: [MenuBarColumn] = []

    /// Название чипа.
    let chipName: String

    /// Источник замеров.
    @ObservationIgnored private let sampler: any SystemSampling
    /// Настройки приложения.
    @ObservationIgnored private let settings: AppSettings
    /// Цикл замеров.
    @ObservationIgnored private var samplingTask: Task<Void, Never>?
    /// Подписки на изменения настроек.
    @ObservationIgnored private var settingsObservationTasks: [Task<Void, Never>] = []
    /// Открыт ли поповер.
    @ObservationIgnored private var isPopoverVisible = false

    /// Создаёт модель с внедрёнными зависимостями.
    init(sampler: any SystemSampling, settings: AppSettings, chipName: String) {
        self.sampler = sampler
        self.settings = settings
        self.chipName = chipName
    }

    deinit {
        samplingTask?.cancel()
        settingsObservationTasks.forEach { $0.cancel() }
    }

    /// Подписывается на настройки и запускает замеры; повторный вызов ничего не делает.
    func startObservingSettings() {
        guard settingsObservationTasks.isEmpty else { return }
        let settings = settings
        settingsObservationTasks = [
            Task { [weak self] in
                for await _ in Observations({ (settings.updateInterval, settings.menuBarStyle) }) {
                    guard let self else { return }
                    restartSampling()
                }
            },
            Task { [weak self] in
                for await _ in Observations({ settings.visibleMenuBarItems }) {
                    guard let self else { return }
                    refreshMenuBarColumns()
                }
            },
        ]
    }

    /// Поповер открыт — замеряем сразу и дальше по интервалу.
    func popoverDidAppear() {
        isPopoverVisible = true
        restartSampling()
    }

    /// Поповер закрыт — останавливаем замеры, если меню-бару они не нужны.
    func popoverDidDisappear() {
        isPopoverVisible = false
        if !isSamplingNeeded {
            stopSampling()
        }
    }

    /// История метрики для графика.
    func history(for metric: SystemMetric) -> MetricHistory {
        histories[metric] ?? MetricHistory(capacity: Self.historyCapacity)
    }

    /// Текстовая сводка для буфера обмена.
    func makeSummary() -> String {
        var lines = [chipName]
        var cpuParts = [MetricFormatter.percent(snapshot.cpuLoad), MetricFormatter.fullTemperature(snapshot.cpuTemperature)]
        if let fanSpeed = snapshot.fanSpeed {
            cpuParts.append(String(localized: "fan \(MetricFormatter.fullFanSpeed(fanSpeed)) rpm"))
        }
        lines.append(String(localized: "CPU: \(cpuParts.joined(separator: " · "))"))
        lines.append(String(localized: "GPU: \(MetricFormatter.fullTemperature(snapshot.gpuTemperature))"))
        if let chipPower = snapshot.chipPower {
            lines.append(String(localized: "Chip power: \(MetricFormatter.fullPower(chipPower))"))
        }
        if let batteryTemperature = snapshot.batteryTemperature {
            lines.append(String(localized: "Battery: \(MetricFormatter.fullTemperature(batteryTemperature))"))
        }
        if let memoryUsage = snapshot.memoryUsage {
            let percent = MetricFormatter.percent(memoryUsage.usedFraction)
            let used = MetricFormatter.memorySize(memoryUsage.usedBytes)
            let total = MetricFormatter.memorySize(memoryUsage.totalBytes)
            lines.append(String(localized: "Memory: \(percent) (\(used) of \(total))"))
        }
        return lines.joined(separator: "\n")
    }

    /// Нужны ли замеры прямо сейчас.
    private var isSamplingNeeded: Bool {
        isPopoverVisible || settings.menuBarStyle.showsValues
    }

    /// Перезапускает цикл замеров с текущим интервалом.
    private func restartSampling() {
        stopSampling()
        refreshMenuBarColumns()
        guard isSamplingNeeded else { return }
        let interval = settings.updateInterval.duration
        let sampler = sampler
        samplingTask = Task { [weak self] in
            while true {
                let snapshot = await sampler.takeSnapshot()
                // `self` не удерживается во время сна, поэтому цикл не продлевает жизнь модели.
                guard !Task.isCancelled, self?.record(snapshot) != nil else { return }
                do {
                    try await Task.sleep(for: interval, tolerance: interval / 5)
                } catch {
                    return
                }
            }
        }
    }

    /// Останавливает цикл замеров.
    private func stopSampling() {
        samplingTask?.cancel()
        samplingTask = nil
    }

    /// Сохраняет новый замер и дополняет историю.
    private func record(_ newSnapshot: SystemSnapshot) {
        snapshot = newSnapshot
        for metric in SystemMetric.allCases {
            if let value = metric.value(in: newSnapshot) {
                histories[metric]?.append(value)
            }
        }
        refreshMenuBarColumns()
    }

    /// Пересобирает значения меню-бара по видимым элементам.
    private func refreshMenuBarColumns() {
        let columns = settings.visibleMenuBarItems.map { MenuBarColumn(item: $0, snapshot: snapshot) }
        if columns != menuBarColumns {
            menuBarColumns = columns
        }
    }
}
