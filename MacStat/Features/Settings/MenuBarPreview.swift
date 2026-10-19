//
//  MenuBarPreview.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

/// Живое превью значка в меню-баре.
struct MenuBarPreview: View {
    /// Источник значений.
    @Environment(MonitorViewModel.self) private var monitor
    /// Источник стиля и элементов.
    @Environment(AppSettings.self) private var settings

    var body: some View {
        MenuBarLabel(monitor: monitor, settings: settings)
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .frame(height: 32)
            .glassEffect(.regular, in: .capsule)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Menu bar preview"))
    }
}
