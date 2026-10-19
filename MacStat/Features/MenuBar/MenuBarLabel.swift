//
//  MenuBarLabel.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import AppKit
import SwiftUI

/// Содержимое значка в меню-баре; модели читаются здесь, чтобы обновлялся только он.
struct MenuBarLabel: View {
    /// Источник значений.
    let monitor: MonitorViewModel
    /// Источник стиля и плотности.
    let settings: AppSettings

    var body: some View {
        if let image = MenuBarImageFactory.makeImage(
            style: settings.menuBarStyle,
            density: settings.menuBarDensity,
            columns: monitor.menuBarColumns
        ) {
            Image(nsImage: image)
        } else {
            Image(systemName: MenuBarImageFactory.fallbackSymbolName)
        }
    }
}
