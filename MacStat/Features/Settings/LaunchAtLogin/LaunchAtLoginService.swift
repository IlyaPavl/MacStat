//
//  LaunchAtLoginService.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

/// Управление автозапуском при входе в систему.
protocol LaunchAtLoginService {
    /// Включён ли автозапуск.
    var isEnabled: Bool { get }
    /// Включает или выключает автозапуск.
    func setEnabled(_ enabled: Bool) throws
}
