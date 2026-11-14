//
//  ThermalStatus+ProcessInfo.swift
//  MacStat
//

import Foundation

extension ThermalStatus {
    /// Переводит системное состояние в сохраняемое событие.
    nonisolated init(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal: self = .normal
        case .fair: self = .elevated
        case .serious: self = .high
        case .critical: self = .critical
        @unknown default: self = .elevated
        }
    }
}
