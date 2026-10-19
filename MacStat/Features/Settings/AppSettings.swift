//
//  AppSettings.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Foundation
import Observation

/// Настройки приложения, сохраняемые в `UserDefaults`.
@Observable
final class AppSettings {
    /// Ключи в `UserDefaults`.
    private enum Key {
        /// Стиль меню-бара.
        static let menuBarStyle = "menuBarStyle"
        /// Плотность меню-бара.
        static let menuBarDensity = "menuBarDensity"
        /// Элементы меню-бара.
        static let menuBarItems = "menuBarItems"
        /// Интервал обновления.
        static let updateInterval = "updateInterval"
        /// Метрики прошлой версии; читается только при переносе.
        static let legacyMenuBarMetrics = "menuBarMetrics"
        /// Верх столбца прошлой версии; читается только при переносе.
        static let legacyStackedTopMetric = "stackedTopMetric"
        /// Низ столбца прошлой версии; читается только при переносе.
        static let legacyStackedBottomMetric = "stackedBottomMetric"
    }

    /// Стиль прошлой версии, в котором показывался один столбец.
    private static let legacyStackedStyle = "stacked"

    /// Вид значка в меню-баре.
    var menuBarStyle: MenuBarStyle {
        didSet { defaults.set(menuBarStyle.rawValue, forKey: Key.menuBarStyle) }
    }

    /// Расстояния между элементами значка.
    var menuBarDensity: MenuBarDensity {
        didSet { defaults.set(menuBarDensity.rawValue, forKey: Key.menuBarDensity) }
    }

    /// Элементы значка по порядку: одиночные метрики и столбцы.
    var menuBarItems: [MenuBarItem] {
        didSet { saveMenuBarItems() }
    }

    /// Как часто снимать замеры.
    var updateInterval: UpdateInterval {
        didSet { defaults.set(updateInterval.rawValue, forKey: Key.updateInterval) }
    }

    /// Хранилище настроек.
    @ObservationIgnored private let defaults: UserDefaults

    /// Загружает настройки; отсутствующие берутся по умолчанию, старые переносятся.
    init(defaults: UserDefaults) {
        self.defaults = defaults
        let savedItems = defaults.data(forKey: Key.menuBarItems)
            .flatMap { try? JSONDecoder().decode([MenuBarItem].self, from: $0) }
        menuBarItems = savedItems ?? Self.legacyMenuBarItems(in: defaults)
        menuBarStyle = defaults.string(forKey: Key.menuBarStyle).flatMap(MenuBarStyle.init(rawValue:)) ?? .twoRows
        menuBarDensity = defaults.string(forKey: Key.menuBarDensity).flatMap(MenuBarDensity.init(rawValue:)) ?? .standard
        updateInterval = UpdateInterval(rawValue: defaults.integer(forKey: Key.updateInterval)) ?? .twoSeconds
        if savedItems == nil {
            saveMenuBarItems()
            removeLegacyKeys()
        }
    }

    /// Элементы, которые сейчас выводятся в меню-бар.
    var visibleMenuBarItems: [MenuBarItem] {
        menuBarStyle.showsValues ? menuBarItems : []
    }

    /// Добавляет одиночную метрику — первую, которой ещё нет в значке.
    func addMenuBarItem() {
        let usedMetrics = Set(menuBarItems.flatMap(\.metrics))
        let metric = SystemMetric.allCases.first { !usedMetrics.contains($0) } ?? .cpuLoad
        menuBarItems.append(MenuBarItem(primary: metric))
    }

    /// Удаляет элемент.
    func removeMenuBarItem(_ item: MenuBarItem) {
        menuBarItems.removeAll { $0.id == item.id }
    }

    /// Переносит элементы `ids` перед элементом `targetID`, сохраняя их порядок; `nil` — в конец.
    func moveMenuBarItems(_ ids: [MenuBarItem.ID], before targetID: MenuBarItem.ID?) {
        let movingIDs = Set(ids)
        if let targetID, movingIDs.contains(targetID) { return }
        let moved = menuBarItems.filter { movingIDs.contains($0.id) }
        var remaining = menuBarItems.filter { !movingIDs.contains($0.id) }
        let insertionIndex = targetID.flatMap { id in remaining.firstIndex { $0.id == id } } ?? remaining.endIndex
        remaining.insert(contentsOf: moved, at: insertionIndex)
        menuBarItems = remaining
    }

    /// Сохраняет элементы меню-бара.
    private func saveMenuBarItems() {
        if let data = try? JSONEncoder().encode(menuBarItems) {
            defaults.set(data, forKey: Key.menuBarItems)
        }
    }

    /// Убирает ключи прошлой версии после переноса.
    private func removeLegacyKeys() {
        for key in [Key.legacyMenuBarMetrics, Key.legacyStackedTopMetric, Key.legacyStackedBottomMetric] {
            defaults.removeObject(forKey: key)
        }
    }

    /// Элементы из настроек прошлой версии: столбец, если был выбран он, иначе включённые метрики.
    private static func legacyMenuBarItems(in defaults: UserDefaults) -> [MenuBarItem] {
        if defaults.string(forKey: Key.menuBarStyle) == legacyStackedStyle {
            let top = defaults.string(forKey: Key.legacyStackedTopMetric).flatMap(SystemMetric.init(rawValue:))
            let bottom = defaults.string(forKey: Key.legacyStackedBottomMetric).flatMap(SystemMetric.init(rawValue:))
            return [MenuBarItem(primary: top ?? .cpuTemperature, secondary: bottom ?? .cpuLoad)]
        }
        let shownMetrics = defaults.stringArray(forKey: Key.legacyMenuBarMetrics)
            .map { Set($0.compactMap(SystemMetric.init(rawValue:))) } ?? Set(SystemMetric.allCases)
        return SystemMetric.allCases.filter(shownMetrics.contains).map { MenuBarItem(primary: $0) }
    }
}
