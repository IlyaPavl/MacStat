//
//  PopoverFooter.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import AppKit
import SwiftUI

/// Нижняя панель поповера: интервал, копирование, настройки, выход.
struct PopoverFooter: View {
    /// Расстояние между кнопками.
    private static let buttonSpacing: CGFloat = 8

    /// Модель мониторинга.
    @Environment(MonitorViewModel.self) private var viewModel
    /// Настройки приложения.
    @Environment(AppSettings.self) private var settings
    /// Открывает окно настроек.
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        @Bindable var settings = settings
        GlassEffectContainer(spacing: Self.buttonSpacing) {
            HStack(spacing: Self.buttonSpacing) {
                Menu {
                    Picker("Update interval", selection: $settings.updateInterval) {
                        ForEach(UpdateInterval.allCases) { interval in
                            Text(interval.title).tag(interval)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    Label("Update interval", systemImage: "arrow.clockwise")
                }
                .menuStyle(.button)
                .menuIndicator(.hidden)
                .help(Text("Update interval"))

                Spacer()

                Button("Copy summary", systemImage: "doc.on.doc", action: copySummary)
                    .help(Text("Copy summary"))
                Button("Settings…", systemImage: "gearshape", action: showSettingsWindow)
                    .help(Text("Settings…"))
                Button("Quit MacStat", systemImage: "power") {
                    NSApplication.shared.terminate(nil)
                }
                .help(Text("Quit MacStat"))
            }
            .buttonStyle(GlassIconButtonStyle())
        }
    }

    /// Копирует сводку в буфер обмена.
    private func copySummary() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(viewModel.makeSummary(), forType: .string)
    }

    /// Выводит приложение на передний план и открывает настройки.
    private func showSettingsWindow() {
        NSApplication.shared.activate()
        openSettings()
    }
}
