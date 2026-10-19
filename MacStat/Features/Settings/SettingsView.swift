//
//  SettingsView.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

/// Окно настроек.
struct SettingsView: View {
    /// Настройки приложения.
    @Environment(AppSettings.self) private var settings
    /// Модель автозапуска.
    @Environment(LaunchAtLoginViewModel.self) private var launchAtLogin

    var body: some View {
        @Bindable var settings = settings
        @Bindable var launchAtLogin = launchAtLogin
        Form {
            Section("Menu bar") {
                Picker("Style", selection: $settings.menuBarStyle) {
                    ForEach(MenuBarStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }

                ForEach(MenuBarMetric.allCases) { metric in
                    Toggle(isOn: $settings[isShown: metric]) {
                        Label {
                            Text(metric.title)
                        } icon: {
                            Image(systemName: metric.symbolName)
                        }
                    }
                }
                .disabled(!settings.menuBarStyle.showsValues)
            }

            Section("General") {
                Picker("Update interval", selection: $settings.updateInterval) {
                    ForEach(UpdateInterval.allCases) { interval in
                        Text(interval.title).tag(interval)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Launch at login", isOn: $launchAtLogin.isToggleOn)
                if let errorMessage = launchAtLogin.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear(perform: launchAtLogin.reloadStatus)
    }
}
