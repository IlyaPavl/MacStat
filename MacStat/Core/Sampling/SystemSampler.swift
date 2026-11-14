//
//  SystemSampler.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Foundation
import OSLog

/// Снимает метрики с железа вне главного потока; SMC открывается при первом замере.
actor SystemSampler: SystemSampling {
    /// Читатели и хранилище доступны только этому актору.
    private let historyStore: HistoryStore
    private let processReader = ProcessReader()
    private let batteryReader = BatteryReader()
    private let logger = Logger(subsystem: "ipavlov.MacStat", category: "History")
    /// Батарея обновляется не чаще одного раза в пять секунд.
    private var battery: BatteryReading?
    private var batteryReadAt: TimeInterval?

    /// Соединение с SMC; `nil`, если недоступно.
    private lazy var smc = SMCClient()
    /// Чтение загрузки CPU.
    private let cpuLoadReader = CPULoadReader()
    /// Чтение памяти.
    private let memoryReader = MemoryReader()
    /// Найденные датчики; заполняется при первом замере.
    private var sensorCatalog: SMCSensorCatalog?

    /// Другой URL изолирует файлы интеграционных тестов от истории пользователя.
    init(historyURL: URL = URL.applicationSupportDirectory.appending(path: "MacStat/history.json")) {
        historyStore = HistoryStore(url: historyURL)
    }

    /// Полный обход процессов выполняется только по запросу открытой панели.
    func sampleProcesses() -> [ProcessRow] {
        processReader.read()
    }

    /// Не переносит CPU-дельты через закрытие панели или сон.
    func resetProcesses() {
        processReader.reset()
    }

    /// Подготавливает графики вне главного потока.
    func historyPoints(hours: Int) -> [SystemMetric: [HistoryPoint]] {
        historyStore.points(hours: hours)
    }

    /// Запоминает переход, а не очередной замер того же состояния.
    func recordThermal(_ state: ThermalStatus) {
        historyStore.thermal(state)
    }

    /// При ошибке данные остаются в памяти, а причина доступна в Console.
    func flushHistory() -> Bool {
        let saved = historyStore.flush()
        if !saved {
            logger.error("Unable to save metric history")
        }
        return saved
    }

    /// Делает один замер всех метрик.
    func takeSnapshot() -> SystemSnapshot {
        let sensors = loadSensorCatalog()
        let now = ProcessInfo.processInfo.systemUptime
        if batteryReadAt.map({ now - $0 >= 5 }) ?? true {
            battery = batteryReader.read()
            batteryReadAt = now
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
        if !historyStore.record(snapshot) {
            logger.error("Unable to save metric history")
        }
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
