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
        /// Метрики в меню-баре.
        static let menuBarMetrics = "menuBarMetrics"
        /// Интервал обновления.
        static let updateInterval = "updateInterval"
    }

    /// Вид значка в меню-баре.
    var menuBarStyle: MenuBarStyle {
        didSet { defaults.set(menuBarStyle.rawValue, forKey: Key.menuBarStyle) }
    }

    /// Метрики, показанные в меню-баре.
    var menuBarMetrics: Set<MenuBarMetric> {
        didSet { defaults.set(menuBarMetrics.map(\.rawValue).sorted(), forKey: Key.menuBarMetrics) }
    }

    /// Как часто снимать замеры.
    var updateInterval: UpdateInterval {
        didSet { defaults.set(updateInterval.rawValue, forKey: Key.updateInterval) }
    }

    /// Хранилище настроек.
    @ObservationIgnored private let defaults: UserDefaults

    /// Загружает настройки; отсутствующие берутся по умолчанию.
    init(defaults: UserDefaults) {
        self.defaults = defaults
        menuBarStyle = defaults.string(forKey: Key.menuBarStyle).flatMap(MenuBarStyle.init(rawValue:)) ?? .compact
        menuBarMetrics = defaults.stringArray(forKey: Key.menuBarMetrics)
            .map { Set($0.compactMap(MenuBarMetric.init(rawValue:))) } ?? Set(MenuBarMetric.allCases)
        updateInterval = UpdateInterval(rawValue: defaults.integer(forKey: Key.updateInterval)) ?? .twoSeconds
    }

    /// Показана ли метрика в меню-баре.
    func isShown(_ metric: MenuBarMetric) -> Bool {
        menuBarMetrics.contains(metric)
    }

    /// Вкл/выкл метрики для `Toggle`: `$settings[isShown: metric]`.
    subscript(isShown metric: MenuBarMetric) -> Bool {
        get { isShown(metric) }
        set {
            if newValue {
                menuBarMetrics.insert(metric)
            } else {
                menuBarMetrics.remove(metric)
            }
        }
    }
}
