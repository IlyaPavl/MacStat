//
//  HistoryModels.swift
//  MacStat
//

import Foundation

/// Подготовленная точка графика; сегменты не соединяются через пропуски.
nonisolated struct HistoryPoint: Identifiable, Equatable, Sendable {
    /// Абсолютное время замера или начала группы.
    var date: Date
    /// Среднее значение в исходных единицах метрики.
    var value: Double
    /// Наибольшее значение группы.
    var peak: Double
    /// Номер непрерывного участка.
    var segment: Int
    var id: Date { date }
}

/// Минутный бакет. Строковые ключи сохраняют совместимость при смене метрик.
nonisolated struct HistoryBucket: Codable, Sendable {
    /// Начало минуты в UTC.
    var t: Date
    /// Средние значения присутствующих метрик.
    var avg: [String: Float]
    /// Максимумы присутствующих метрик.
    var max: [String: Float]
    /// Нужны для продолжения незакрытой минуты после перезапуска; старые файлы без них читаются.
    var counts: [String: Int]? = nil
}

/// Смена теплового состояния хранится событием, а не числовой метрикой.
nonisolated struct ThermalEvent: Codable, Equatable, Sendable {
    /// Абсолютное время замера или начала группы.
    var date: Date
    /// Новое тепловое состояние.
    var state: ThermalStatus
}

/// Версия формата позволяет безопасно отбросить несовместимый файл.
nonisolated struct HistoryDocument: Codable, Sendable {
    /// Версия формата файла.
    var version = 1
    /// Закрытые и сохранённая текущая минута.
    var buckets: [HistoryBucket] = []
    /// Переходы теплового состояния за срок хранения.
    var thermalEvents: [ThermalEvent] = []
}
