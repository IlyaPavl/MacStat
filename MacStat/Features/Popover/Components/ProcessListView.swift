//
//  ProcessListView.swift
//  MacStat
//
//  Created by Ilya Pavlov on 27.11.2026.
//

import SwiftUI

/// Три самых нагружающих приложения по CPU и по памяти; CPU в процентах одного ядра.
struct ProcessListView: View {
    /// Отобранные процессы последнего обхода.
    let top: TopProcesses

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            section("Top CPU", rows: top.cpu) { row in
                ((row.cpu ?? 0) / 100).formatted(.percent.precision(.fractionLength(0)))
            }
            section("Top memory", rows: top.memory) { row in
                MetricFormatter.memorySize(row.memory)
            }
        }
        .font(.caption)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    /// Заголовок и до трёх строк «название — значение»; пока данных нет, «Measuring…».
    private func section(
        _ title: LocalizedStringKey,
        rows: [ProcessRow],
        text: @escaping (ProcessRow) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).fontWeight(.semibold)
            if rows.isEmpty {
                Text("Measuring…").foregroundStyle(.secondary)
            }
            ForEach(rows) { row in
                HStack {
                    Text(verbatim: row.name).lineLimit(1).truncationMode(.middle)
                    Spacer(minLength: 8)
                    Text(verbatim: text(row)).monospacedDigit()
                }
            }
        }
    }
}
