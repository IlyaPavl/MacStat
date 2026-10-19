//
//  SystemSampler.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

/// Снимает метрики с железа вне главного потока; SMC открывается при первом замере.
actor SystemSampler: SystemSampling {
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
        return SystemSnapshot(
            cpuLoad: cpuLoadReader.readLoad(),
            cpuTemperature: smc?.averageTemperature(of: sensors.cpuTemperatureSensors),
            gpuTemperature: smc?.averageTemperature(of: sensors.gpuTemperatureSensors),
            fanSpeed: smc?.averageFanSpeed(of: sensors.fanSensors),
            memoryUsage: memoryReader.readUsage()
        )
    }

    /// Каталог датчиков; при первом вызове ищет их в SMC.
    private func loadSensorCatalog() -> SMCSensorCatalog {
        if let sensorCatalog { return sensorCatalog }
        let discovered = smc?.discoverSensors() ?? .empty
        sensorCatalog = discovered
        return discovered
    }
}
