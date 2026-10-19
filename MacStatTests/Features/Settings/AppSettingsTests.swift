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

    @Test func visibleMetricsFollowStyle() throws {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AppSettings(defaults: defaults)
        settings.menuBarMetrics = [.memory, .cpuLoad]
        settings.stackedTopMetric = .cpuTemperature
        settings.stackedBottomMetric = .fanSpeed

        settings.menuBarStyle = .twoRows
        #expect(settings.visibleMenuBarMetrics == [.cpuLoad, .memory])
        settings.menuBarStyle = .stacked
        #expect(settings.visibleMenuBarMetrics == [.cpuTemperature, .fanSpeed])
        settings.menuBarStyle = .iconOnly
        #expect(settings.visibleMenuBarMetrics.isEmpty)
    }

    @Test func persistsNewOptions() throws {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AppSettings(defaults: defaults)
        settings.menuBarStyle = .stacked
        settings.menuBarDensity = .compact
        settings.stackedBottomMetric = .gpuTemperature

        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.menuBarStyle == .stacked)
        #expect(reloaded.menuBarDensity == .compact)
        #expect(reloaded.stackedBottomMetric == .gpuTemperature)
    }

    @Test func keepsLegacyTwoRowsValue() throws {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("compact", forKey: "menuBarStyle")
        #expect(AppSettings(defaults: defaults).menuBarStyle == .twoRows)
    }
}
