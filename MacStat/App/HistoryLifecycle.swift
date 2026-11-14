import AppKit

final class HistoryLifecycle: NSObject, NSApplicationDelegate {
    static var sampler: (any SystemSampling)?
    private var quitting = false
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !quitting else { return .terminateLater }
        guard let sampler = Self.sampler else { return .terminateNow }
        quitting = true
        Task {
            _ = await sampler.flushHistory()
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}
