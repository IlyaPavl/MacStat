//
//  HistoryRecorder.swift
//  MacStat
//
//  Created by Ilya Pavlov on 27.11.2026.
//

import Foundation
import OSLog
import Synchronization

/// Потокобезопасный доступ к истории: замеры пишет `SystemSampler`, сохраняет `HistoryLifecycle`.
nonisolated final class HistoryRecorder: Sendable {
    /// История под блокировкой; удерживается только на время одной операции.
    private let store: Mutex<HistoryStore>

    /// Файл истории задаётся снаружи, чтобы тесты не трогали файл пользователя.
    init(url: URL) {
        store = Mutex(HistoryStore(url: url))
    }

    /// Добавляет замер.
    func record(_ snapshot: SystemSnapshot) {
        store.withLock { $0.record(snapshot) }
    }

    /// Точки графиков за выбранное число часов.
    func points(hours: Int) -> [SystemMetric: [HistoryPoint]] {
        store.withLock { $0.points(hours: hours) }
    }

    /// Сохраняет историю; ошибка записи попадает в Console, данные остаются в памяти.
    func flush() {
        guard !store.withLock({ $0.flush() }) else { return }
        Logger(subsystem: "ipavlov.MacStat", category: "History").error("Unable to save metric history")
    }
}

extension HistoryRecorder {
    /// Файл истории в Application Support.
    static var defaultURL: URL {
        URL.applicationSupportDirectory.appending(path: "MacStat/history.json")
    }
}
