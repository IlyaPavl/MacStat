import SwiftUI

struct DiagnosticsView: View {
    @Environment(MonitorViewModel.self) private var monitor
    private func bytes(_ value: UInt64) -> String { ByteCountFormatter.string(fromByteCount: Int64(clamping: value), countStyle: .memory) }
    private var thermalColor: Color {
        switch monitor.thermalStatus {
        case .normal: .green
        case .elevated: .yellow
        case .high: .orange
        case .critical: .red
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("Thermal state: \(String(localized: String.LocalizationValue(monitor.thermalStatus.title)))")
            } icon: { Image(systemName: "thermometer.medium") }
                .font(.caption.weight(.medium))
                .padding(6)
                .background(thermalColor.opacity(0.15), in: .capsule)
            if let battery = monitor.snapshot.battery {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Battery").font(.caption.weight(.semibold))
                    HStack {
                        if let health = battery.health { Text("Health \(health, specifier: "%.0f") %") }
                        if let cycles = battery.cycles { Text("\(cycles) cycles") }
                    }
                    if let watts = battery.watts {
                        HStack {
                            if battery.charging { Text("Charging") }
                            else if battery.external { Text("Connected to power") }
                            else { Text("Discharging") }
                            Text(verbatim: String(format: "%+.1f W", watts)).monospacedDigit()
                        }
                    }
                    if battery.external, let adapter = battery.adapterWatts { Text("Adapter: \(adapter, specifier: "%.0f") W") }
                }.font(.caption)
            }
            if !monitor.processes.isEmpty {
                processList(cpu: true)
                processList(cpu: false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    private func processList(cpu: Bool) -> some View {
        let rows = cpu
            ? monitor.processes.filter { $0.cpu != nil }.sorted { ($0.cpu ?? 0) > ($1.cpu ?? 0) }
            : monitor.processes.sorted { $0.memory > $1.memory }
        return VStack(alignment: .leading, spacing: 3) {
            Text(cpu ? "Top CPU (% of one core)" : "Top memory").font(.caption.weight(.semibold))
            if rows.isEmpty { Text("Measuring…").foregroundStyle(.secondary) }
            ForEach(Array(rows.prefix(3))) { row in
                HStack {
                    Text(verbatim: row.name).lineLimit(1).truncationMode(.middle)
                    Spacer()
                    Text(verbatim: cpu ? String(format: "%.1f %%", row.cpu ?? 0) : bytes(row.memory)).monospacedDigit()
                }
            }
        }.font(.caption)
    }
}

struct MemoryDetailsView: View {
    let usage: MemoryUsage
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let pressure = usage.pressure {
                let color: Color = pressure == .normal ? .green : pressure == .warning ? .yellow : .red
                RoundedRectangle(cornerRadius: 2).fill(color).frame(height: 3)
                Text(pressure == .normal ? "Memory pressure: normal" : pressure == .warning ? "Memory pressure: warning" : "Memory pressure: critical")
            }
            if let swap = usage.swapBytes { Text("Swap: \(ByteCountFormatter.string(fromByteCount: Int64(clamping: swap), countStyle: .memory))") }
            if let compressed = usage.compressedBytes { Text("Compressed: \(ByteCountFormatter.string(fromByteCount: Int64(clamping: compressed), countStyle: .memory))") }
        }.font(.caption2).foregroundStyle(.secondary)
    }
}
