//
//  MenuBarThermalTests.swift
//  MacStatTests
//

import Testing
@testable import MacStat

/// В нормальном состоянии предупреждение не добавляет ширину даже в режиме одной иконки.
@MainActor
struct MenuBarThermalTests {
    @Test func onlySeriousStatesAddWarning() {
        for state in [ThermalStatus.normal, .elevated] {
            #expect(MenuBarImageFactory.makeImage(style: .iconOnly, density: .compact, columns: [], thermalStatus: state) == nil)
        }
        for state in [ThermalStatus.high, .critical] {
            let image = MenuBarImageFactory.makeImage(style: .iconOnly, density: .compact, columns: [], thermalStatus: state)
            #expect(image != nil)
            #expect(image?.isTemplate == true)
        }
    }
}
