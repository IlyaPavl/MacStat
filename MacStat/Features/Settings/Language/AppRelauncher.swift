//
//  AppRelauncher.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

/// Перезапуск приложения.
protocol AppRelauncher {
    /// Запускает новый экземпляр и завершает текущий.
    func relaunch() async throws
}
