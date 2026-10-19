//
//  MetricSection.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

/// Общий макет секции: заголовок, крупное значение и подробности.
struct MetricSection<HeaderAccessory: View, Value: View, Detail: View>: View {
    /// Заголовок.
    let title: LocalizedStringResource
    /// Иконка заголовка.
    let symbolName: String
    /// Доп. информация справа от заголовка.
    @ViewBuilder let headerAccessory: HeaderAccessory
    /// Крупное значение.
    @ViewBuilder let value: Value
    /// График или полоса под значением.
    @ViewBuilder let detail: Detail

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(title, systemImage: symbolName)
                Spacer()
                headerAccessory
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            value
                .font(.title2.weight(.medium).monospacedDigit())
                .contentTransition(.numericText())

            detail
        }
        .padding(.vertical, 10)
    }
}
