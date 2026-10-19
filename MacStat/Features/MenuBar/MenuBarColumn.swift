//
//  MenuBarColumn.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

/// Готовые значения одного элемента значка.
enum MenuBarColumn: Equatable {
    /// Одна метрика в текущем стиле.
    case single(MenuBarReading)
    /// Два значения друг над другом без подписей.
    case stacked(top: MenuBarReading, bottom: MenuBarReading)

    /// Значения элемента для текущего замера.
    init(item: MenuBarItem, snapshot: SystemSnapshot) {
        let primary = MenuBarReading(metric: item.primary, snapshot: snapshot)
        if let secondary = item.secondary {
            self = .stacked(top: primary, bottom: MenuBarReading(metric: secondary, snapshot: snapshot))
        } else {
            self = .single(primary)
        }
    }
}
