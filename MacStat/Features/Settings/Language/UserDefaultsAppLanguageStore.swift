//
//  UserDefaultsAppLanguageStore.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Foundation

/// Язык приложения через `AppleLanguages` в домене приложения — как в Системных настройках.
struct UserDefaultsAppLanguageStore: AppLanguageStore {
    /// Ключ списка языков, который читает `Bundle` при запуске.
    private static let appleLanguagesKey = "AppleLanguages"

    /// Настройки приложения.
    let defaults: UserDefaults
    /// Домен приложения — без глобальных настроек системы.
    let domainName: String

    /// Выбранная локализация из домена приложения.
    var preferredLanguage: String? {
        (defaults.persistentDomain(forName: domainName)?[Self.appleLanguagesKey] as? [String])?.first
    }

    /// Записывает или убирает переопределение языка.
    func setPreferredLanguage(_ identifier: String?) {
        if let identifier {
            defaults.set([identifier], forKey: Self.appleLanguagesKey)
        } else {
            defaults.removeObject(forKey: Self.appleLanguagesKey)
        }
    }
}
