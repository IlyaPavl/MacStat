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
    /// Модель мониторинга.
    @Environment(MonitorViewModel.self) private var viewModel
    /// Настройки приложения.
    @Environment(AppSettings.self) private var settings
    /// Открывает окно настроек.
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        @Bindable var settings = settings
        HStack(spacing: 12) {
            Picker(selection: $settings.updateInterval) {
                ForEach(UpdateInterval.allCases) { interval in
                    Text(interval.title).tag(interval)
                }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .pickerStyle(.menu)
            .fixedSize()
            .help(Text("Update interval"))

            Spacer()

            Button("Copy summary", systemImage: "doc.on.doc", action: copySummary)
            Button("Settings…", systemImage: "gearshape", action: showSettingsWindow)
            Button("Quit MacStat", systemImage: "power") {
                NSApplication.shared.terminate(nil)
            }
        }
        .buttonStyle(.borderless)
        .labelStyle(.iconOnly)
        .foregroundStyle(.secondary)
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
