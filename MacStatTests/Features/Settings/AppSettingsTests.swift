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

    @Test func defaultsToBaseMetricsAsSingleItems() throws {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AppSettings(defaults: defaults)
        let expected: [SystemMetric] = [.cpuLoad, .cpuTemperature, .fanSpeed, .gpuTemperature, .memory]
        #expect(settings.menuBarItems.map(\.metrics) == expected.map { [$0] })
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

    @Test func addsUnusedMetricAndRemovesItems() throws {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AppSettings(defaults: defaults)
        settings.menuBarItems = [MenuBarItem(primary: .cpuLoad, secondary: .cpuTemperature)]

        let added = settings.addMenuBarItem()
        #expect(settings.menuBarItems.map(\.primary) == [.cpuLoad, .chipPower])
        #expect(settings.menuBarItems.last == added)

        let first = try #require(settings.menuBarItems.first)
        #expect(settings.removeMenuBarItem(first.id) == added.id)
        #expect(settings.removeMenuBarItem(added.id) == nil)
        #expect(settings.menuBarItems.isEmpty)
    }

    @Test func movesItemsBeforeTarget() throws {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AppSettings(defaults: defaults)
        settings.menuBarItems = [.cpuLoad, .cpuTemperature, .fanSpeed, .memory].map { MenuBarItem(primary: $0) }
        let ids = settings.menuBarItems.map(\.id)

        settings.moveMenuBarItems([ids[0]], before: ids[3])
        #expect(settings.menuBarItems.map(\.primary) == [.cpuTemperature, .fanSpeed, .cpuLoad, .memory])
        settings.moveMenuBarItems([ids[3]], before: ids[1])
        #expect(settings.menuBarItems.map(\.primary) == [.memory, .cpuTemperature, .fanSpeed, .cpuLoad])
        settings.moveMenuBarItems([ids[2], ids[3]], before: nil)
        #expect(settings.menuBarItems.map(\.primary) == [.cpuTemperature, .cpuLoad, .memory, .fanSpeed])
        settings.moveMenuBarItems([ids[1]], before: ids[1])
        #expect(settings.menuBarItems.map(\.primary) == [.cpuTemperature, .cpuLoad, .memory, .fanSpeed])
    }

    @Test func stackingPicksPartnerMetric() {
        var item = MenuBarItem(primary: .gpuTemperature)
        item.isStacked = true
        #expect(item.secondary == .fanSpeed)
        item.secondary = .memory
        item.isStacked = true
        #expect(item.secondary == .memory)
        item.isStacked = false
        #expect(item.metrics == [.gpuTemperature])
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
