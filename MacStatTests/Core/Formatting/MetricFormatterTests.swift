//
//  MetricFormatterTests.swift
//  MacStatTests
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Foundation
import Testing
@testable import MacStat

struct MetricFormatterTests {
    @Test func fullFanSpeedFormatting() {
        let locale = Locale(identifier: "en_US")
        #expect(MetricFormatter.fullFanSpeed(nil, locale: locale) == "—")
        #expect(MetricFormatter.fullFanSpeed(0, locale: locale) == "0")
        #expect(MetricFormatter.fullFanSpeed(1849.6, locale: locale) == "1850")
        #expect(MetricFormatter.fullFanSpeed(1500, locale: Locale(identifier: "ru_RU")) == "1500")
    }

    @Test func shortPowerFormatting() {
        let locale = Locale(identifier: "en_US")
        #expect(MetricFormatter.shortPower(nil, locale: locale) == "—")
        #expect(MetricFormatter.shortPower(4.54, locale: locale) == "4.5W")
        #expect(MetricFormatter.shortPower(14.6, locale: locale) == "15W")
        #expect(MetricFormatter.shortPower(1.66, locale: Locale(identifier: "ru_RU")) == "1,7W")
    }

    @Test func percentAndTemperature() {
        #expect(MetricFormatter.percent(0.234) == "23%")
        #expect(MetricFormatter.shortTemperature(54.6) == "55°")
        #expect(MetricFormatter.shortTemperature(nil) == "—")
    }
}
