//
//  WorkspaceAppRelauncher.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import AppKit

/// Перезапуск через `NSWorkspace`.
struct WorkspaceAppRelauncher: AppRelauncher {
    /// Запускает новый экземпляр приложения и завершает текущий.
    func relaunch() async throws {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        try await NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration)
        NSApplication.shared.terminate(nil)
    }
}
