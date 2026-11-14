//
//  MonitorViewModel.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import AppKit
import Foundation
import Observation

/// Периодически снимает метрики и готовит их для меню-бара и поповера.
@Observable
final class MonitorViewModel {
    /// Тепловое состояние меняется только по системным уведомлениям.
    private(set) var thermalStatus = ThermalStatus(ProcessInfo.processInfo.thermalState)
    /// Процессы последнего обхода; пусто при закрытой панели.
    private(set) var processes: [ProcessRow] = []
    /// Уже уменьшенные наборы точек для всех графиков.
    private(set) var chartPoints: [SystemMetric: [HistoryPoint]] = [:]
    /// Выбранный период истории.
    var historyHours = 1 {
        didSet {
            guard historyHours != oldValue else { return }
            requestHistory()
        }
    }

    /// Последний замер.
    private(set) var snapshot: SystemSnapshot = .empty
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
    /// Во сне фоновые циклы остановлены; после пробуждения начинаются новые дельты.
    @ObservationIgnored private var isSleeping = false
    /// Подписки и задачи отменяются вместе с моделью.
    @ObservationIgnored private var diagnosticTasks: [Task<Void, Never>] = []
    @ObservationIgnored private var processTask: Task<Void, Never>?
    @ObservationIgnored private var historyTask: Task<Void, Never>?
    /// Номер запроса исключает запоздавший ответ старого периода истории.
    @ObservationIgnored private var historyRequest = 0

    /// Создаёт модель с внедрёнными зависимостями.
    init(sampler: any SystemSampling, settings: AppSettings, chipName: String) {
        self.sampler = sampler
        self.settings = settings
        self.chipName = chipName
    }

    deinit {
        historyTask?.cancel()
        processTask?.cancel()
        diagnosticTasks.forEach { $0.cancel() }
        samplingTask?.cancel()
        settingsObservationTasks.forEach { $0.cancel() }
    }

    /// Подписывается на настройки и запускает замеры; повторный вызов ничего не делает.
    func startObservingSettings() {
        guard settingsObservationTasks.isEmpty else { return }
        observeDiagnostics()
        let settings = settings
        settingsObservationTasks = [
            Task { [weak self] in
                for await _ in Observations({ settings.updateInterval }) {
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

    /// Панель открыта — сразу читаем метрики, историю и первый замер процессов.
    func popoverDidAppear() {
        guard !isPopoverVisible else { return }
        isPopoverVisible = true
        requestHistory()
        restartProcesses()
    }

    /// При закрытии панели сбор истории продолжается, а обход процессов прекращается.
    func popoverDidDisappear() {
        isPopoverVisible = false
        processTask?.cancel()
        processTask = nil
        historyTask?.cancel()
        historyTask = nil
        historyRequest += 1
        processes = []
    }

    /// Перечитывает точки только для видимой панели, отменяя устаревший запрос.
    private func requestHistory() {
        guard isPopoverVisible else { return }
        historyTask?.cancel()
        historyRequest += 1
        let request = historyRequest
        let hours = historyHours
        let sampler = sampler
        historyTask = Task { [weak self] in
            let points = await sampler.historyPoints(hours: hours)
            guard !Task.isCancelled, let self, historyRequest == request, isPopoverVisible else { return }
            chartPoints = points
        }
    }

    /// Цикл живёт только при открытой панели; первый CPU-замер намеренно пустой.
    private func restartProcesses() {
        processTask?.cancel()
        processes = []
        guard isPopoverVisible, !isSleeping else { return }
        let sampler = sampler
        processTask = Task { [weak self] in
            await sampler.resetProcesses()
            while !Task.isCancelled {
                let rows = await sampler.sampleProcesses()
                guard !Task.isCancelled else { return }
                self?.processes = rows
                do {
                    try await Task.sleep(for: .seconds(2))
                } catch {
                    return
                }
            }
        }
    }

    /// Подписки не используют таймер для thermal state и не передают Notification между акторами.
    private func observeDiagnostics() {
        let sampler = sampler
        diagnosticTasks = [
            Task { [weak self] in
                let changes = NotificationCenter.default.notifications(named: ProcessInfo.thermalStateDidChangeNotification)
                    .map { _ in true }
                await sampler.recordThermal(ThermalStatus(ProcessInfo.processInfo.thermalState))
                for await _ in changes {
                    guard !Task.isCancelled, let self else { return }
                    thermalStatus = ThermalStatus(ProcessInfo.processInfo.thermalState)
                    await sampler.recordThermal(thermalStatus)
                }
            },
            Task { [weak self] in
                let changes = NSWorkspace.shared.notificationCenter.notifications(named: NSWorkspace.willSleepNotification)
                    .map { _ in true }
                for await _ in changes {
                    guard !Task.isCancelled, let self else { return }
                    isSleeping = true
                    stopSampling()
                    processTask?.cancel()
                    processes = []
                    _ = await sampler.flushHistory()
                }
            },
            Task { [weak self] in
                let changes = NSWorkspace.shared.notificationCenter.notifications(named: NSWorkspace.didWakeNotification)
                    .map { _ in true }
                for await _ in changes {
                    guard !Task.isCancelled, let self else { return }
                    isSleeping = false
                    thermalStatus = ThermalStatus(ProcessInfo.processInfo.thermalState)
                    await sampler.recordThermal(thermalStatus)
                    restartSampling()
                    restartProcesses()
                }
            },
        ]
    }

    /// Текстовая сводка для буфера обмена.
    func makeSummary() -> String {
        var lines = [chipName, String(localized: "Thermal state: \(String(localized: thermalStatus.title))")]
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
        if let memory = snapshot.memoryUsage {
            if let pressure = memory.pressure {
                lines.append(String(localized: pressure.title))
            }
            if let swap = memory.swapBytes {
                lines.append(String(localized: "Swap: \(MetricFormatter.memorySize(swap))"))
            }
            if let compressed = memory.compressedBytes {
                lines.append(String(localized: "Compressed: \(MetricFormatter.memorySize(compressed))"))
            }
        }
        if let battery = snapshot.battery {
            if let health = battery.health {
                lines.append(String(localized: "Health: \((health / 100).formatted(.percent.precision(.fractionLength(0))))"))
            }
            if let cycles = battery.cycles {
                lines.append(String(localized: "Cycles: \(cycles)"))
            }
            if let watts = battery.watts {
                lines.append(String(localized: "Battery power: \(MetricFormatter.signedPower(watts))"))
            }
            if battery.external == true, let adapter = battery.adapterWatts {
                lines.append(String(localized: "Adapter: \(MetricFormatter.fullPower(adapter))"))
            }
        }
        return lines.joined(separator: "\n")
    }

    /// Перезапускает цикл замеров с текущим интервалом.
    private func restartSampling() {
        stopSampling()
        refreshMenuBarColumns()
        guard !isSleeping else { return }
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

    /// Публикует замер и запрашивает графики, только если панель видна.
    private func record(_ newSnapshot: SystemSnapshot) {
        snapshot = newSnapshot
        requestHistory()
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
