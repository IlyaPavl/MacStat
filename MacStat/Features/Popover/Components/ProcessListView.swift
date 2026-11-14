//
//  ProcessListView.swift
//  MacStat
//

import SwiftUI

/// Два списка по три строки; CPU измеряется в процентах одного ядра.
struct ProcessListView: View {
    let rows: [ProcessRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            processList(cpu: true)
            processList(cpu: false)
        }
        .font(.caption)
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    /// Стабильный порядок при равных значениях не даёт строкам прыгать.
    private func processList(cpu: Bool) -> some View {
        let sorted = cpu ? rows.filter { $0.cpu != nil }.sorted {
            $0.cpu == $1.cpu ? $0.id < $1.id : ($0.cpu ?? 0) > ($1.cpu ?? 0)
        } : rows.sorted {
            $0.memory == $1.memory ? $0.id < $1.id : $0.memory > $1.memory
        }
        return VStack(alignment: .leading, spacing: 3) {
            if cpu {
                Text("Top CPU (% of one core)").fontWeight(.semibold)
            } else {
                Text("Top memory").fontWeight(.semibold)
            }
            if sorted.isEmpty {
                Text("Measuring…").foregroundStyle(.secondary)
            }
            ForEach(Array(sorted.prefix(3))) { row in
                HStack {
                    Text(verbatim: row.name)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Text(verbatim: value(for: row, cpu: cpu)).monospacedDigit()
                }
            }
        }
    }

    /// Имена процессов остаются исходными, числовые значения используют текущую локаль.
    private func value(for row: ProcessRow, cpu: Bool) -> String {
        if cpu, let value = row.cpu {
            return (value / 100).formatted(.percent.precision(.fractionLength(1)))
        }
        return MetricFormatter.memorySize(row.memory)
    }
}
