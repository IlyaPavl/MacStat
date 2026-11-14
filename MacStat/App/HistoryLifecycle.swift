//
//  HistoryLifecycle.swift
//  MacStat
//

import AppKit

/// Обычный выход ждёт атомарной записи истории, не блокируя главный поток.
final class HistoryLifecycle: NSObject, NSApplicationDelegate {
    /// Источник передаётся точкой входа приложения, без глобального синглтона.
    var sampler: (any SystemSampling)?
    private var isQuitting = false

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !isQuitting else { return .terminateLater }
        guard let sampler else { return .terminateNow }
        isQuitting = true
        Task {
            _ = await sampler.flushHistory()
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}
