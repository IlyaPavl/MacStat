//
//  SystemSampler.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Foundation

/// Снимает метрики с железа вне главного потока; SMC открывается при первом замере.
actor SystemSampler: SystemSampling {
    /// Чтение батареи.
    private let batteryReader = BatteryReader()
    /// Обход процессов.
    private let processReader = ProcessReader()
    /// История метрик.
    private let history: HistoryRecorder
    /// Соединение с SMC; `nil`, если недоступно.
    private lazy var smc = SMCClient()
    /// Чтение загрузки CPU.
    private let cpuLoadReader = CPULoadReader()
    /// Чтение памяти.
    private let memoryReader = MemoryReader()
    /// Найденные датчики; заполняется при первом замере.
    private var sensorCatalog: SMCSensorCatalog?

    /// История внедряется, чтобы её же сохранял `HistoryLifecycle`, а тесты писали во временный файл.
    init(history: HistoryRecorder) {
        self.history = history
    }

    /// Делает один замер всех метрик и добавляет его в историю.
    func takeSnapshot() -> SystemSnapshot {
        let sensors = loadSensorCatalog()
        let snapshot = SystemSnapshot(
            cpuLoad: cpuLoadReader.readLoad(),
            cpuTemperature: smc?.averageTemperature(of: sensors.cpuTemperatureSensors),
            gpuTemperature: smc?.averageTemperature(of: sensors.gpuTemperatureSensors),
            fanSpeed: smc?.averageFanSpeed(of: sensors.fanSensors),
            batteryTemperature: smc?.averageTemperature(of: sensors.batteryTemperatureSensors),
            chipPower: smc?.averagePower(of: sensors.chipPowerSensors),
            memoryUsage: memoryReader.readUsage(),
            battery: batteryReader.read()
        )
        history.record(snapshot)
        return snapshot
    }

    /// Обходит процессы и отбирает самые тяжёлые; вызывается только при открытой панели.
    func sampleProcesses() -> TopProcesses {
        TopProcesses(rows: processReader.read())
    }

    /// Следующий обход снова начнёт без CPU-дельты.
    func resetProcesses() {
        processReader.reset()
    }

    /// Точки графиков за выбранное число часов.
    func historyPoints(hours: Int) -> [SystemMetric: [HistoryPoint]] {
        history.points(hours: hours)
    }

    /// Каталог датчиков; при первом вызове ищет их в SMC.
    private func loadSensorCatalog() -> SMCSensorCatalog {
        if let sensorCatalog { return sensorCatalog }
        let discovered = smc?.discoverSensors() ?? .empty
        sensorCatalog = discovered
        return discovered
    }
}
