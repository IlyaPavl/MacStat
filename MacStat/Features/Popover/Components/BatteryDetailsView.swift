//
//  BatteryDetailsView.swift
//  MacStat
//
//  Created by Ilya Pavlov on 27.11.2026.
//

import SwiftUI

/// Здоровье, циклы и мощность батареи; отсутствующие поля не показываются.
struct BatteryDetailsView: View {
    /// Сведения о батарее.
    let reading: BatteryReading

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Battery").fontWeight(.semibold)
            HStack(spacing: 10) {
                if let health = reading.health {
                    Text("Health: \((health / 100).formatted(.percent.precision(.fractionLength(0))))")
                }
                if let cycles = reading.cycles {
                    Text("Cycles: \(cycles)")
                }
            }
            HStack(spacing: 10) {
                if reading.isCharging == true {
                    Text("Charging")
                } else if reading.isExternalPowerConnected == true {
                    Text("Connected to power")
                } else if reading.isExternalPowerConnected == false {
                    Text("Discharging")
                }
                if let watts = reading.watts {
                    Text(verbatim: MetricFormatter.signedPower(watts)).monospacedDigit()
                }
            }
            if reading.isExternalPowerConnected == true, let adapter = reading.adapterWatts {
                Text("Adapter: \(MetricFormatter.fullPower(adapter))")
            }
        }
        .font(.caption)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}
