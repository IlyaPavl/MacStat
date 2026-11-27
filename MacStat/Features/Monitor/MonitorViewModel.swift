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
    /// Последний замер.
    private(set) var snapshot: SystemSnapshot = .empty
    /// Тепловое состояние системы; обновляется вместе с замером.
    private(set) var thermalState = ProcessInfo.processInfo.thermalState
    /// Самые тяжёлые процессы последнего обхода; пусто при закрытой панели.
    private(set) var processes = TopProcesses.empty
    /// Точки графиков за выбранный период.
    private(set) var chartPoints: [SystemMetric: [HistoryPoint]] = [:]
    /// Момент, на который построены точки; правый край оси времени.
    private(set) var chartEnd = Date()
    /// Период графиков в часах: 1, 6, 24 или 48.
    var historyHours = 1 {
        didSet {
            if historyHours != oldValue { requestChartPoints() }
        }
    }
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
    /// Обход процессов, пока панель открыта.
    @ObservationIgnored private var processTask: Task<Void, Never>?
    /// Запрос точек графиков.
    @ObservationIgnored private var chartTask: Task<Void, Never>?
    /// Когда графики пересобирались в последний раз.
    @ObservationIgnored private var lastChartRefresh: Date?
    /// Интервал работающего цикла замеров.
    @ObservationIgnored private var activeInterval: Duration?

    /// Создаёт модель с внедрёнными зависимостями.
    init(sampler: any SystemSampling, settings: AppSettings, chipName: String) {
        self.sampler = sampler
        self.settings = settings
        self.chipName = chipName
    }

    deinit {
        processTask?.cancel()
        chartTask?.cancel()
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

    /// Поповер открыт — читаем графики и процессы; замеры ускоряются до выбранного интервала.
    func popoverDidAppear() {
        guard !isPopoverVisible else { return }
        isPopoverVisible = true
        requestChartPoints()
        startProcessLoop()
        if samplingInterval != activeInterval {
            restartSampling()
        }
    }

    /// Поповер закрыт — процессы и графики больше не читаем; история продолжает писаться.
    func popoverDidDisappear() {
        isPopoverVisible = false
        processTask?.cancel()
        processTask = nil
        chartTask?.cancel()
        chartTask = nil
        processes = .empty
        if samplingInterval != activeInterval {
            restartSampling()
        }
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

    /// История пишется всегда, поэтому замеры не останавливаются. Когда их никто не видит,
    /// достаточно раза в 5 секунд: минутным бакетам этого хватает.
    private var samplingInterval: Duration {
        let configured = settings.updateInterval.duration
        let isUnobserved = !isPopoverVisible && !settings.menuBarStyle.showsValues
        return isUnobserved ? max(configured, .seconds(5)) : configured
    }

    /// Перезапускает цикл замеров с текущим интервалом.
    private func restartSampling() {
        stopSampling()
        refreshMenuBarColumns()
        let interval = samplingInterval
        activeInterval = interval
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

    /// Сохраняет новый замер.
    private func record(_ newSnapshot: SystemSnapshot) {
        snapshot = newSnapshot
        let thermal = ProcessInfo.processInfo.thermalState
        if thermal != thermalState {
            thermalState = thermal
        }
        refreshChartPointsIfDue()
        refreshMenuBarColumns()
    }

    /// Бакеты меняются раз в минуту, поэтому длинные периоды обновляем редко, а час — чаще.
    private func refreshChartPointsIfDue() {
        guard isPopoverVisible else { return }
        let minimum: TimeInterval = historyHours == 1 ? 5 : 60
        if let last = lastChartRefresh, Date().timeIntervalSince(last) < minimum { return }
        requestChartPoints()
    }

    /// Запрашивает точки графиков; запоздавший ответ предыдущего запроса отбрасывается.
    private func requestChartPoints() {
        guard isPopoverVisible else { return }
        chartTask?.cancel()
        let now = Date()
        lastChartRefresh = now
        let hours = historyHours
        let sampler = sampler
        chartTask = Task { [weak self] in
            let points = await sampler.historyPoints(hours: hours)
            guard !Task.isCancelled else { return }
            self?.setChartPoints(points, end: now)
        }
    }

    /// Публикует точки графиков.
    private func setChartPoints(_ points: [SystemMetric: [HistoryPoint]], end: Date) {
        chartPoints = points
        chartEnd = end
    }

    /// Обходит процессы раз в 2 секунды, пока панель открыта; первый замер без CPU.
    private func startProcessLoop() {
        processTask?.cancel()
        processes = .empty
        let sampler = sampler
        processTask = Task { [weak self] in
            await sampler.resetProcesses()
            while !Task.isCancelled {
                let top = await sampler.sampleProcesses()
                // `self` не удерживается на время паузы.
                guard !Task.isCancelled, self?.setProcesses(top) != nil else { return }
                do {
                    try await Task.sleep(for: .seconds(2))
                } catch {
                    return
                }
            }
        }
    }

    /// Публикует процессы; без изменений панель не перестраивается.
    private func setProcesses(_ top: TopProcesses) {
        if top != processes {
            processes = top
        }
    }

    /// Пересобирает значения меню-бара по видимым элементам.
    private func refreshMenuBarColumns() {
        let columns = settings.visibleMenuBarItems.map { MenuBarColumn(item: $0, snapshot: snapshot) }
        if columns != menuBarColumns {
            menuBarColumns = columns
        }
    }
}
