//
//  MetricHistoryTests.swift
//  MacStatTests
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Testing
@testable import MacStat

struct MetricHistoryTests {
    @Test func dropsOldestBeyondCapacity() {
        var history = MetricHistory(capacity: 3)
        [1, 2, 3, 4].forEach { history.append($0) }
        #expect(history.values == [2, 3, 4])
    }
}
