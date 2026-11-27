//
//  HistoryLifecycle.swift
//  MacStat
//
//  Created by Ilya Pavlov on 27.11.2026.
//

import AppKit

/// Сохраняет историю при засыпании и выходе.
final class HistoryLifecycle {
    /// История метрик.
    private let history: HistoryRecorder
    /// Подписки на системные уведомления.
    private var observers: [(center: NotificationCenter, token: any NSObjectProtocol)] = []

    /// Подписывается на сон и выход сразу при создании.
    init(history: HistoryRecorder) {
        self.history = history
        let workspace = NSWorkspace.shared.notificationCenter
        let sleep = workspace.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: nil) { _ in
            history.flush()
        }
        // Запись занимает миллисекунды и не ждёт цикла замеров, поэтому выход не задерживается.
        let terminate = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: nil
        ) { _ in
            history.flush()
        }
        observers = [(workspace, sleep), (.default, terminate)]
    }

    isolated deinit {
        observers.forEach { $0.center.removeObserver($0.token) }
    }
}
