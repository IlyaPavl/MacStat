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

                Picker("Density", selection: $settings.menuBarDensity) {
                    ForEach(MenuBarDensity.allCases) { density in
                        Text(density.title).tag(density)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!settings.menuBarStyle.showsValues)
            }

            if settings.menuBarStyle.showsValues {
                Section {
                    MenuBarPreview()
                    ForEach($settings.menuBarItems) { $item in
                        MenuBarItemRow(item: $item)
                    }
                    .reorderable()
                    Button("Add item", systemImage: "plus", action: settings.addMenuBarItem)
                } header: {
                    Text("Items")
                } footer: {
                    Text("Drag rows to reorder. Turn on Stacked to show two values in one column.")
                        .foregroundStyle(.secondary)
                }
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
        .reorderContainer(for: MenuBarItem.self) { difference in
            let targetID: MenuBarItem.ID? = switch difference.destination.position {
            case .before(let id): id
            case .end: nil
            }
            withAnimation {
                settings.moveMenuBarItems(difference.sources, before: targetID)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .fixedSize(horizontal: false, vertical: true)
        .animation(.default, value: settings.menuBarStyle)
        .animation(.default, value: settings.menuBarItems.map(\.id))
        .onAppear(perform: launchAtLogin.reloadStatus)
    }
}
