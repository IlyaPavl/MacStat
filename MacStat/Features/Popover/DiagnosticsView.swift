//
//  DiagnosticsView.swift
//  MacStat
//

import SwiftUI

/// Дополнительные сведения без настроек и управляющих действий над процессами.
struct DiagnosticsView: View {
    @Environment(MonitorViewModel.self) private var monitor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ThermalBadge(state: monitor.thermalStatus)
            if let battery = monitor.snapshot.battery {
                BatteryDetailsView(reading: battery)
            }
            if !monitor.processes.isEmpty {
                ProcessListView(rows: monitor.processes)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
