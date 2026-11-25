//
//  TopProcessesTests.swift
//  MacStatTests
//
//  Created by Ilya Pavlov on 27.11.2026.
//

import Testing
@testable import MacStat

struct TopProcessesTests {
    @Test func picksThreeHighestWithStableTies() {
        let rows = [
            ProcessRow(id: "d", name: "D", cpu: 5, memory: 10),
            ProcessRow(id: "b", name: "B", cpu: 50, memory: 30),
            ProcessRow(id: "a", name: "A", cpu: 50, memory: 30),
            ProcessRow(id: "c", name: "C", cpu: 180, memory: 20),
        ]
        let top = TopProcesses(rows: rows)
        #expect(top.cpu.map(\.id) == ["c", "a", "b"])
        #expect(top.memory.map(\.id) == ["a", "b", "c"])
    }

    @Test func cpuListWaitsForSecondSample() {
        let top = TopProcesses(rows: [ProcessRow(id: "a", name: "A", cpu: nil, memory: 10)])
        #expect(top.cpu.isEmpty)
        #expect(top.memory.map(\.id) == ["a"])
    }
}
