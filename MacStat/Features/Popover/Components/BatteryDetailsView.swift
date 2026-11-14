//
//  BatteryDetailsView.swift
//  MacStat
//

import SwiftUI

/// Развёрнутые сведения о батарее; отсутствующие поля не отображаются.
struct BatteryDetailsView: View {
    let reading: BatteryReading

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Battery").font(.caption.weight(.semibold))
            HStack {
                if let health = reading.health {
                    Text("Health: \((health / 100).formatted(.percent.precision(.fractionLength(0))))")
                }
                if let cycles = reading.cycles {
                    Text("Cycles: \(cycles)")
                }
            }
            HStack {
                if reading.charging == true {
                    Text("Charging")
                } else if reading.external == true {
                    Text("Connected to power")
                } else if reading.external == false {
                    Text("Discharging")
                }
                if let watts = reading.watts {
                    Text(verbatim: MetricFormatter.signedPower(watts)).monospacedDigit()
                }
            }
            if reading.external == true, let adapter = reading.adapterWatts {
                Text("Adapter: \(MetricFormatter.fullPower(adapter))")
            }
        }
        .font(.caption)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}
