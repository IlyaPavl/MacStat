//
//  MacStatApp.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

/// Точка входа: значок в меню-баре и окно настроек.
@main
struct MacStatApp: App {
    /// Настройки приложения.
    @State private var settings: AppSettings
    /// Модель мониторинга.
    @State private var monitor: MonitorViewModel
    /// Модель автозапуска.
    @State private var launchAtLogin: LaunchAtLoginViewModel

    /// Собирает зависимости и запускает мониторинг.
    init() {
        let settings = AppSettings(defaults: .standard)
        let monitor = MonitorViewModel(
            sampler: SystemSampler(),
            settings: settings,
            chipName: ChipInfo.marketingName()
        )
        monitor.startObservingSettings()
        _settings = State(initialValue: settings)
        _monitor = State(initialValue: monitor)
        _launchAtLogin = State(initialValue: LaunchAtLoginViewModel(service: MainAppLaunchAtLoginService()))
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environment(monitor)
                .environment(settings)
        } label: {
            MenuBarLabel(monitor: monitor, settings: settings)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(settings)
                .environment(launchAtLogin)
        }
    }
}
