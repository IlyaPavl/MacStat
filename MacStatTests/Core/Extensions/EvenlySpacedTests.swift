//
//  EvenlySpacedTests.swift
//  MacStatTests
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Testing
@testable import MacStat

struct EvenlySpacedTests {
    @Test func spreadsAcrossWholeArray() {
        #expect(Array(0..<10).evenlySpaced(upTo: 5) == [0, 2, 4, 6, 8])
        #expect([1, 2].evenlySpaced(upTo: 5) == [1, 2])
    }
}
