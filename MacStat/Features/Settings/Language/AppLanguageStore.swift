//
//  AppLanguageStore.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

/// Хранилище выбранного языка приложения.
protocol AppLanguageStore {
    /// Выбранная локализация; `nil` — системный язык.
    var preferredLanguage: String? { get }
    /// Сохраняет локализацию; `nil` — вернуться к системному языку.
    func setPreferredLanguage(_ identifier: String?)
}
