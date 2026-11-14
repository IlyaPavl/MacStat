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
    /// Делегат сохраняет историю до завершения приложения.
    @NSApplicationDelegateAdaptor(HistoryLifecycle.self) private var lifecycle

    /// Настройки приложения.
    @State private var settings: AppSettings
    /// Модель мониторинга.
    @State private var monitor: MonitorViewModel
    /// Модель автозапуска.
    @State private var launchAtLogin: LaunchAtLoginViewModel
    /// Модель выбора языка.
    @State private var language: LanguageViewModel

    /// Собирает зависимости и запускает мониторинг.
    init() {
        let settings = AppSettings(defaults: .standard)
        let sampler = SystemSampler()
        let monitor = MonitorViewModel(
            sampler: sampler,
            settings: settings,
            chipName: ChipInfo.marketingName()
        )
        monitor.startObservingSettings()
        _settings = State(initialValue: settings)
        _monitor = State(initialValue: monitor)
        _launchAtLogin = State(initialValue: LaunchAtLoginViewModel(service: MainAppLaunchAtLoginService()))
        let languageStore = UserDefaultsAppLanguageStore(
            defaults: .standard,
            domainName: Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName
        )
        _language = State(initialValue: LanguageViewModel(
            store: languageStore,
            localizations: Bundle.main.localizations,
            relauncher: WorkspaceAppRelauncher()
        ))
        lifecycle.sampler = sampler
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
                .environment(monitor)
                .environment(settings)
                .environment(launchAtLogin)
                .environment(language)
        }
    }
}
