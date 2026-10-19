//
//  TemperatureLabel.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

/// Температура с иконкой термометра.
struct TemperatureLabel: View {
    /// Температура, °C.
    let celsius: Double?

    var body: some View {
        Label {
            Text(MetricFormatter.shortTemperature(celsius))
        } icon: {
            Image(systemName: MenuBarMetric.cpuTemperature.symbolName)
                .foregroundStyle(.secondary)
        }
    }
}
