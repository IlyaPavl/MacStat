//
//  SystemSampler.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

/// Снимает метрики с железа вне главного потока; SMC открывается при первом замере.
import Foundation

actor SystemSampler: SystemSampling {
    private let historyStore = HistoryStore()
    private let processes = ProcessReader()
    private var battery: BatteryReading?
    private var batteryReadAt = Date.distantPast

    func processRows(reset: Bool) -> [ProcessRow] {
        if reset { processes.reset(); return [] }
        return processes.read()
    }
    func historyPoints(hours: Int) -> [SystemMetric: [HistoryPoint]] { historyStore.points(hours: hours) }
    func recordThermal(_ state: ThermalStatus) { historyStore.thermal(state) }
    func flushHistory() -> Bool { historyStore.flush() }

    /// Соединение с SMC; `nil`, если недоступно.
    private lazy var smc = SMCClient()
    /// Чтение загрузки CPU.
    private let cpuLoadReader = CPULoadReader()
    /// Чтение памяти.
    private let memoryReader = MemoryReader()
    /// Найденные датчики; заполняется при первом замере.
    private var sensorCatalog: SMCSensorCatalog?

    /// Делает один замер всех метрик.
    func takeSnapshot() -> SystemSnapshot {
        let sensors = loadSensorCatalog()
        if Date().timeIntervalSince(batteryReadAt) >= 5 {
            battery = BatteryReading.read(); batteryReadAt = Date()
        }
        let snapshot = SystemSnapshot(
            cpuLoad: cpuLoadReader.readLoad(),
            cpuTemperature: smc?.averageTemperature(of: sensors.cpuTemperatureSensors),
            gpuTemperature: smc?.averageTemperature(of: sensors.gpuTemperatureSensors),
            fanSpeed: smc?.averageFanSpeed(of: sensors.fanSensors),
            batteryTemperature: smc?.averageTemperature(of: sensors.batteryTemperatureSensors),
            chipPower: smc?.averagePower(of: sensors.chipPowerSensors),
            memoryUsage: memoryReader.readUsage(),
            battery: battery
        )
        historyStore.record(snapshot)
        return snapshot
    }

    /// Каталог датчиков; при первом вызове ищет их в SMC.
    private func loadSensorCatalog() -> SMCSensorCatalog {
        if let sensorCatalog { return sensorCatalog }
        let discovered = smc?.discoverSensors() ?? .empty
        sensorCatalog = discovered
        return discovered
    }
}
