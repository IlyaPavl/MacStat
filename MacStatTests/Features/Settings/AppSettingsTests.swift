//
//  AppSettingsTests.swift
//  MacStatTests
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Foundation
import Testing
@testable import MacStat

@MainActor
struct AppSettingsTests {
    /// Отдельный `UserDefaults` на тест, чтобы не трогать настройки приложения.
    private let suiteName = "AppSettingsTests.\(UUID().uuidString)"

    @Test func defaultsToEveryMetricAsSingleItem() throws {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AppSettings(defaults: defaults)
        #expect(settings.menuBarItems.map(\.metrics) == SystemMetric.allCases.map { [$0] })
    }

    @Test func iconOnlyHidesItems() throws {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AppSettings(defaults: defaults)
        settings.menuBarStyle = .iconOnly
        #expect(settings.visibleMenuBarItems.isEmpty)
        settings.menuBarStyle = .iconsAndValues
        #expect(settings.visibleMenuBarItems == settings.menuBarItems)
    }

    @Test func persistsMixedItems() throws {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AppSettings(defaults: defaults)
        let items = [
            MenuBarItem(primary: .cpuTemperature, secondary: .cpuLoad),
            MenuBarItem(primary: .memory),
            MenuBarItem(primary: .gpuTemperature, secondary: .fanSpeed),
        ]
        settings.menuBarItems = items
        settings.menuBarDensity = .compact

        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.menuBarItems == items)
        #expect(reloaded.menuBarDensity == .compact)
    }

    @Test func addsUnusedMetricAndMovesItems() throws {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AppSettings(defaults: defaults)
        settings.menuBarItems = [MenuBarItem(primary: .cpuLoad, secondary: .cpuTemperature)]

        settings.addMenuBarItem()
        #expect(settings.menuBarItems.map(\.primary) == [.cpuLoad, .fanSpeed])

        let added = try #require(settings.menuBarItems.last)
        #expect(!settings.canMoveMenuBarItem(added, by: 1))
        settings.moveMenuBarItem(added, by: -1)
        #expect(settings.menuBarItems.map(\.primary) == [.fanSpeed, .cpuLoad])

        settings.removeMenuBarItem(added)
        #expect(settings.menuBarItems.map(\.primary) == [.cpuLoad])
    }

    @Test func dragMovesItems() throws {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AppSettings(defaults: defaults)
        settings.menuBarItems = [.cpuLoad, .cpuTemperature, .fanSpeed, .memory].map { MenuBarItem(primary: $0) }

        settings.moveMenuBarItems(fromOffsets: [0], toOffset: 3)
        #expect(settings.menuBarItems.map(\.primary) == [.cpuTemperature, .fanSpeed, .cpuLoad, .memory])
        settings.moveMenuBarItems(fromOffsets: [3], toOffset: 0)
        #expect(settings.menuBarItems.map(\.primary) == [.memory, .cpuTemperature, .fanSpeed, .cpuLoad])
        settings.moveMenuBarItems(fromOffsets: [0, 2], toOffset: 4)
        #expect(settings.menuBarItems.map(\.primary) == [.cpuTemperature, .cpuLoad, .memory, .fanSpeed])
    }

    @Test func migratesLegacyStackedStyle() throws {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("stacked", forKey: "menuBarStyle")
        defaults.set("gpuTemperature", forKey: "stackedTopMetric")
        defaults.set("fanSpeed", forKey: "stackedBottomMetric")

        let settings = AppSettings(defaults: defaults)
        #expect(settings.menuBarStyle == .twoRows)
        #expect(settings.menuBarItems.map(\.metrics) == [[.gpuTemperature, .fanSpeed]])
        #expect(defaults.object(forKey: "stackedTopMetric") == nil)
    }

    @Test func migratesLegacyMetricSelection() throws {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("compact", forKey: "menuBarStyle")
        defaults.set(["memory", "cpuLoad"], forKey: "menuBarMetrics")

        let settings = AppSettings(defaults: defaults)
        #expect(settings.menuBarStyle == .twoRows)
        #expect(settings.menuBarItems.map(\.metrics) == [[.cpuLoad], [.memory]])
        #expect(AppSettings(defaults: defaults).menuBarItems == settings.menuBarItems)
    }
}
