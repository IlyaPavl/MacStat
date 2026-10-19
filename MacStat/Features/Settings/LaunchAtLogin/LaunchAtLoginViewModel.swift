//
//  LaunchAtLoginViewModel.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Foundation
import Observation

/// Состояние переключателя автозапуска.
@Observable
final class LaunchAtLoginViewModel {
    /// Реальный статус автозапуска.
    private(set) var isEnabled: Bool
    /// Текст последней ошибки.
    private(set) var errorMessage: String?

    /// Системный сервис автозапуска.
    @ObservationIgnored private let service: any LaunchAtLoginService

    /// Создаёт модель и читает текущий статус.
    init(service: any LaunchAtLoginService) {
        self.service = service
        isEnabled = service.isEnabled
    }

    /// Перечитывает статус (его могли поменять в Системных настройках).
    func reloadStatus() {
        isEnabled = service.isEnabled
    }

    /// Привязка для `Toggle`; всегда показывает реальный статус.
    var isToggleOn: Bool {
        get { isEnabled }
        set { updateRegistration(enabled: newValue) }
    }

    /// Меняет автозапуск и запоминает ошибку, если не вышло.
    private func updateRegistration(enabled: Bool) {
        do {
            try service.setEnabled(enabled)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isEnabled = service.isEnabled
    }
}
