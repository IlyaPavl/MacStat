//
//  SMCClient.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import IOKit

/// Читает датчики через драйвер AppleSMC (80-байтная структура `SMCKeyData_t`).
/// Буферы переиспользуются, поэтому замеры не выделяют память.
nonisolated final class SMCClient {
    /// Смещения полей в структуре `SMCKeyData_t`.
    private enum Layout {
        /// Размер структуры, байт.
        static let bufferSize = 80
        /// Ключ.
        static let keyOffset = 0
        /// Размер значения из `keyInfo`.
        static let dataSizeOffset = 28
        /// Тип значения из `keyInfo`.
        static let dataTypeOffset = 32
        /// Код ответа SMC.
        static let resultOffset = 40
        /// Команда.
        static let commandOffset = 42
        /// Индекс ключа для `readKeyAtIndex`.
        static let indexOffset = 44
        /// Байты значения.
        static let valueOffset = 48
        /// Максимальный размер значения, байт.
        static let maxValueSize = 32
    }

    /// Команды SMC.
    private enum Command: UInt8 {
        /// Прочитать значение.
        case readValue = 5
        /// Прочитать ключ по индексу.
        case readKeyAtIndex = 8
        /// Прочитать размер и тип значения.
        case readKeyInfo = 9
    }

    /// Коды типов значений SMC.
    private enum DataType {
        /// 32-битное float.
        static let float = SMCKey("flt ").code
        /// Знаковое 8.8 с фиксированной точкой.
        static let sp78 = SMCKey("sp78").code
        /// Беззнаковое 14.2 с фиксированной точкой.
        static let fpe2 = SMCKey("fpe2").code
        /// 8-битное целое.
        static let uint8 = SMCKey("ui8 ").code
        /// 16-битное целое.
        static let uint16 = SMCKey("ui16").code
        /// 32-битное целое.
        static let uint32 = SMCKey("ui32").code
    }

    /// Префиксы датчиков P- и E-ядер.
    private static let cpuKeyPrefixes: Set<UInt32> = [SMCKey("Tp").code, SMCKey("Te").code]
    /// Префикс датчиков GPU.
    private static let gpuKeyPrefix = SMCKey("Tg").code
    /// Селектор метода драйвера `handleYPCEvent`.
    private static let structMethodSelector: UInt32 = 2
    /// Реалистичные температуры, °C; остальное — мусор.
    private static let plausibleTemperatureRange = 1.0...130.0
    /// Лимит датчиков CPU: каждое чтение ~0,1 мс, а среднее от прореживания не меняется.
    private static let maxCPUSensorCount = 12
    /// Лимит датчиков GPU.
    private static let maxGPUSensorCount = 6

    /// Открытое соединение с драйвером.
    private let connection: io_connect_t
    /// Буфер запроса.
    private var input = [UInt8](repeating: 0, count: Layout.bufferSize)
    /// Буфер ответа.
    private var output = [UInt8](repeating: 0, count: Layout.bufferSize)

    /// Открывает соединение; `nil`, если SMC недоступен.
    init?() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != IO_OBJECT_NULL else { return nil }
        defer { IOObjectRelease(service) }
        var connection: io_connect_t = 0
        guard IOServiceOpen(service, mach_task_self_, 0, &connection) == kIOReturnSuccess else { return nil }
        self.connection = connection
    }

    deinit {
        IOServiceClose(connection)
    }

    /// Один раз обходит все ключи и отбирает датчики CPU (`Tp*`, `Te*`), GPU (`Tg*`) и вентиляторов.
    func discoverSensors() -> SMCSensorCatalog {
        var cpuSensors: [SMCSensor] = []
        var gpuSensors: [SMCSensor] = []
        for index in 0..<readKeyCount() {
            guard let key = readKey(atIndex: index) else { continue }
            let prefix = key.code >> 16
            let isCPU = Self.cpuKeyPrefixes.contains(prefix)
            let isGPU = prefix == Self.gpuKeyPrefix
            guard isCPU || isGPU,
                  let sensor = readSensorInfo(for: key),
                  sensor.dataType == DataType.float,
                  let value = readValue(of: sensor),
                  Self.plausibleTemperatureRange.contains(value)
            else { continue }
            if isCPU { cpuSensors.append(sensor) } else { gpuSensors.append(sensor) }
        }
        return SMCSensorCatalog(
            cpuTemperatureSensors: cpuSensors.evenlySpaced(upTo: Self.maxCPUSensorCount),
            gpuTemperatureSensors: gpuSensors.evenlySpaced(upTo: Self.maxGPUSensorCount),
            fanSensors: discoverFanSensors()
        )
    }

    /// Средняя температура по датчикам, °C.
    func averageTemperature(of sensors: [SMCSensor]) -> Double? {
        averageValue(of: sensors) { Self.plausibleTemperatureRange.contains($0) }
    }

    /// Средние обороты вентиляторов.
    func averageFanSpeed(of sensors: [SMCSensor]) -> Double? {
        averageValue(of: sensors) { _ in true }
    }

    /// Среднее по датчикам, прошедшим `isValid`.
    private func averageValue(of sensors: [SMCSensor], where isValid: (Double) -> Bool) -> Double? {
        var sum = 0.0
        var count = 0
        for sensor in sensors {
            guard let value = readValue(of: sensor), isValid(value) else { continue }
            sum += value
            count += 1
        }
        return count > 0 ? sum / Double(count) : nil
    }

    /// Текущее значение датчика.
    private func readValue(of sensor: SMCSensor) -> Double? {
        guard sensor.dataSize <= Layout.maxValueSize else { return nil }
        clearInput()
        writeInput(sensor.key.code, at: Layout.keyOffset)
        writeInput(sensor.dataSize, at: Layout.dataSizeOffset)
        guard send(.readValue) else { return nil }
        return decodeValue(type: sensor.dataType, size: Int(sensor.dataSize))
    }

    /// Датчики вентиляторов `F0Ac`, `F1Ac`…
    private func discoverFanSensors() -> [SMCSensor] {
        guard let countSensor = readSensorInfo(for: SMCKey("FNum")),
              let count = readValue(of: countSensor),
              count > 0
        else { return [] }
        return (0..<Int(count)).compactMap { readSensorInfo(for: SMCKey("F\($0)Ac")) }
    }

    /// Сколько всего ключей в SMC.
    private func readKeyCount() -> Int {
        guard let sensor = readSensorInfo(for: SMCKey("#KEY")), let count = readValue(of: sensor) else { return 0 }
        return Int(count)
    }

    /// Ключ по порядковому номеру.
    private func readKey(atIndex index: Int) -> SMCKey? {
        clearInput()
        writeInput(UInt32(index), at: Layout.indexOffset)
        guard send(.readKeyAtIndex) else { return nil }
        return SMCKey(code: readOutput(at: Layout.keyOffset))
    }

    /// Размер и тип значения ключа.
    private func readSensorInfo(for key: SMCKey) -> SMCSensor? {
        clearInput()
        writeInput(key.code, at: Layout.keyOffset)
        guard send(.readKeyInfo) else { return nil }
        return SMCSensor(
            key: key,
            dataSize: readOutput(at: Layout.dataSizeOffset),
            dataType: readOutput(at: Layout.dataTypeOffset)
        )
    }

    /// Переводит байты ответа в число по типу SMC.
    private func decodeValue(type: UInt32, size: Int) -> Double? {
        let offset = Layout.valueOffset
        switch type {
        case DataType.float where size == 4:
            return Double(Float(bitPattern: readOutput(at: offset)))
        case DataType.sp78 where size == 2:
            return Double(Int16(bitPattern: UInt16(bigEndian: readOutput(at: offset)))) / 256
        case DataType.fpe2 where size == 2:
            return Double(UInt16(bigEndian: readOutput(at: offset))) / 4
        case DataType.uint8 where size == 1:
            return Double(output[offset])
        case DataType.uint16 where size == 2:
            return Double(UInt16(bigEndian: readOutput(at: offset)))
        case DataType.uint32 where size == 4:
            return Double(UInt32(bigEndian: readOutput(at: offset)))
        default:
            return nil
        }
    }

    /// Отправляет команду драйверу; `true`, если SMC ответил без ошибки.
    private func send(_ command: Command) -> Bool {
        input[Layout.commandOffset] = command.rawValue
        var outputSize = Layout.bufferSize
        let status = input.withUnsafeBytes { inputBuffer in
            output.withUnsafeMutableBytes { outputBuffer in
                IOConnectCallStructMethod(
                    connection,
                    Self.structMethodSelector,
                    inputBuffer.baseAddress,
                    Layout.bufferSize,
                    outputBuffer.baseAddress,
                    &outputSize
                )
            }
        }
        return status == kIOReturnSuccess && output[Layout.resultOffset] == 0
    }

    /// Обнуляет буфер запроса.
    private func clearInput() {
        input.withUnsafeMutableBufferPointer { $0.update(repeating: 0) }
    }

    /// Пишет число в запрос (little-endian, как в C-структуре).
    private func writeInput(_ value: UInt32, at offset: Int) {
        input.withUnsafeMutableBytes { $0.storeBytes(of: value, toByteOffset: offset, as: UInt32.self) }
    }

    /// Читает число из ответа.
    private func readOutput<T: FixedWidthInteger>(at offset: Int) -> T {
        output.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: T.self) }
    }
}
