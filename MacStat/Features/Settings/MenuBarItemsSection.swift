//
//  MenuBarItemsSection.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

/// Раздел элементов значка: превью из чипов и инспектор выбранного элемента.
struct MenuBarItemsSection: View {
    /// Настройки с элементами.
    @Environment(AppSettings.self) private var settings
    /// Выбранный элемент; `nil` — первый.
    @State private var selectedID: MenuBarItem.ID?

    var body: some View {
        @Bindable var settings = settings
        let activeID = selectedID ?? settings.menuBarItems.first?.id
        Section {
            HStack {
                MenuBarItemsStrip(selectedID: activeID) { selectedID = $0 }
                Spacer()
                ControlGroup {
                    Button("Add item", systemImage: "plus") {
                        selectedID = settings.addMenuBarItem().id
                    }
                    Button("Remove", systemImage: "minus") {
                        if let activeID {
                            selectedID = settings.removeMenuBarItem(activeID)
                        }
                    }
                    .disabled(activeID == nil)
                }
                .labelStyle(.iconOnly)
                .fixedSize()
            }

            if let item = $settings.menuBarItems.first(where: { $0.wrappedValue.id == activeID }) {
                MenuBarItemInspector(item: item)
            }
        } header: {
            Text("Items")
        } footer: {
            Text("Click an item to edit it, drag to reorder.")
                .foregroundStyle(.secondary)
        }
    }
}
