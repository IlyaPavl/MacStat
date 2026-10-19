//
//  MenuBarItemsStrip.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

/// Превью значка из чипов: клик выбирает элемент, перетаскивание меняет порядок.
struct MenuBarItemsStrip: View {
    /// Настройки с элементами.
    @Environment(AppSettings.self) private var settings
    /// Выбранный элемент.
    let selectedID: MenuBarItem.ID?
    /// Выбор элемента.
    let select: (MenuBarItem.ID) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(settings.menuBarItems) { item in
                Button {
                    select(item.id)
                } label: {
                    MenuBarItemChip(item: item, isSelected: item.id == selectedID)
                }
                .buttonStyle(.plain)
            }
            .reorderable()
        }
        .padding(3)
        .frame(minHeight: 32)
        .glassEffect(.regular, in: .capsule)
        .reorderContainer(for: MenuBarItem.self) { difference in
            let targetID: MenuBarItem.ID? = switch difference.destination.position {
            case .before(let id): id
            case .end: nil
            }
            withAnimation {
                settings.moveMenuBarItems(difference.sources, before: targetID)
            }
        }
        .accessibilityLabel(Text("Menu bar preview"))
    }
}

/// Один элемент значка в том виде, как он выглядит в меню-баре.
private struct MenuBarItemChip: View {
    /// Источник значений.
    @Environment(MonitorViewModel.self) private var monitor
    /// Источник стиля и плотности.
    @Environment(AppSettings.self) private var settings
    /// Элемент.
    let item: MenuBarItem
    /// Выбран ли элемент.
    let isSelected: Bool

    var body: some View {
        image
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 8)
            .frame(height: 26)
            .background(isSelected ? Color.accentColor : Color.clear, in: .capsule)
            .contentShape(.capsule)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(item.metrics.map { String(localized: $0.title) }.formatted(.list(type: .and))))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Картинка элемента из той же фабрики, что и меню-бар.
    @ViewBuilder private var image: some View {
        let column = MenuBarColumn(item: item, snapshot: monitor.snapshot)
        if let image = MenuBarImageFactory.makeImage(
            style: settings.menuBarStyle,
            density: settings.menuBarDensity,
            columns: [column]
        ) {
            Image(nsImage: image)
                .renderingMode(.template)
        } else {
            Image(systemName: item.primary.symbolName)
        }
    }
}
