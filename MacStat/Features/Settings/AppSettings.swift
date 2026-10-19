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
        /// Метрики в меню-баре.
        static let menuBarMetrics = "menuBarMetrics"
        /// Верхняя метрика комбинированного столбца.
        static let stackedTopMetric = "stackedTopMetric"
        /// Нижняя метрика комбинированного столбца.
        static let stackedBottomMetric = "stackedBottomMetric"
        /// Интервал обновления.
        static let updateInterval = "updateInterval"
    }

    /// Вид значка в меню-баре.
    var menuBarStyle: MenuBarStyle {
        didSet { defaults.set(menuBarStyle.rawValue, forKey: Key.menuBarStyle) }
    }

    /// Расстояния между элементами значка.
    var menuBarDensity: MenuBarDensity {
        didSet { defaults.set(menuBarDensity.rawValue, forKey: Key.menuBarDensity) }
    }

    /// Метрики, показанные в стилях с несколькими колонками.
    var menuBarMetrics: Set<SystemMetric> {
        didSet { defaults.set(menuBarMetrics.map(\.rawValue).sorted(), forKey: Key.menuBarMetrics) }
    }

    /// Верхняя строка комбинированного столбца.
    var stackedTopMetric: SystemMetric {
        didSet { defaults.set(stackedTopMetric.rawValue, forKey: Key.stackedTopMetric) }
    }

    /// Нижняя строка комбинированного столбца.
    var stackedBottomMetric: SystemMetric {
        didSet { defaults.set(stackedBottomMetric.rawValue, forKey: Key.stackedBottomMetric) }
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
        menuBarStyle = defaults.string(forKey: Key.menuBarStyle).flatMap(MenuBarStyle.init(rawValue:)) ?? .twoRows
        menuBarDensity = defaults.string(forKey: Key.menuBarDensity).flatMap(MenuBarDensity.init(rawValue:)) ?? .standard
        menuBarMetrics = defaults.stringArray(forKey: Key.menuBarMetrics)
            .map { Set($0.compactMap(SystemMetric.init(rawValue:))) } ?? Set(SystemMetric.allCases)
        stackedTopMetric = defaults.string(forKey: Key.stackedTopMetric).flatMap(SystemMetric.init(rawValue:)) ?? .cpuTemperature
        stackedBottomMetric = defaults.string(forKey: Key.stackedBottomMetric).flatMap(SystemMetric.init(rawValue:)) ?? .cpuLoad
        updateInterval = UpdateInterval(rawValue: defaults.integer(forKey: Key.updateInterval)) ?? .twoSeconds
    }

    /// Метрики, которые сейчас выводятся в меню-бар, по порядку.
    var visibleMenuBarMetrics: [SystemMetric] {
        switch menuBarStyle {
        case .twoRows, .iconsAndValues: SystemMetric.allCases.filter(isShown)
        case .stacked: [stackedTopMetric, stackedBottomMetric]
        case .iconOnly: []
        }
    }

    /// Включена ли метрика для стилей с несколькими колонками.
    func isShown(_ metric: SystemMetric) -> Bool {
        menuBarMetrics.contains(metric)
    }

    /// Вкл/выкл метрики для `Toggle`: `$settings[isShown: metric]`.
    subscript(isShown metric: SystemMetric) -> Bool {
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
