//
//  MainAppLaunchAtLoginService.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import ServiceManagement

/// Автозапуск самого приложения через `SMAppService`.
struct MainAppLaunchAtLoginService: LaunchAtLoginService {
    /// Включён ли автозапуск.
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Регистрирует или снимает автозапуск.
    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
