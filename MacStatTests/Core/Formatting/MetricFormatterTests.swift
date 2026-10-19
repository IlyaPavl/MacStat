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
    @Test func shortFanSpeedFormatting() {
        let locale = Locale(identifier: "en_US")
        #expect(MetricFormatter.shortFanSpeed(nil, locale: locale) == "—")
        #expect(MetricFormatter.shortFanSpeed(0, locale: locale) == "0")
        #expect(MetricFormatter.shortFanSpeed(1849, locale: locale) == "1.8k")
        #expect(MetricFormatter.shortFanSpeed(1900, locale: Locale(identifier: "ru_RU")) == "1,9k")
    }

    @Test func percentAndTemperature() {
        #expect(MetricFormatter.percent(0.234) == "23%")
        #expect(MetricFormatter.shortTemperature(54.6) == "55°")
        #expect(MetricFormatter.shortTemperature(nil) == "—")
    }
}
