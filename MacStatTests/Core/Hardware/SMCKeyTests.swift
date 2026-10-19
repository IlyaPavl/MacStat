//
//  SMCKeyTests.swift
//  MacStatTests
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Testing
@testable import MacStat

struct SMCKeyTests {
    @Test func fourCharCodeRoundTrip() {
        let key = SMCKey("F0Ac")
        #expect(key.code == 0x4630_4163)
        #expect(key.name == "F0Ac")
    }
}
