//
//  LanguageViewModel.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Foundation
import Observation

/// Выбор языка интерфейса; новый язык применяется после перезапуска.
@Observable
final class LanguageViewModel {
    /// Варианты: системный и все локализации приложения.
    let languages: [AppLanguage]
    /// Выбранный язык; сохраняется сразу.
    var selection: AppLanguage {
        didSet { store.setPreferredLanguage(selection.identifier) }
    }
    /// Текст последней ошибки перезапуска.
    private(set) var errorMessage: String?

    /// Язык, с которым запущено приложение.
    @ObservationIgnored private let launchSelection: AppLanguage
    /// Хранилище выбора.
    @ObservationIgnored private let store: any AppLanguageStore
    /// Перезапуск приложения.
    @ObservationIgnored private let relauncher: any AppRelauncher

    /// Создаёт модель; `localizations` — коды из `Bundle.localizations`.
    init(store: any AppLanguageStore, localizations: [String], relauncher: any AppRelauncher) {
        self.store = store
        self.relauncher = relauncher
        let specificLanguages = localizations
            .filter { $0 != "Base" }
            .map(AppLanguage.specific)
            .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
        languages = [.system] + specificLanguages
        let saved = store.preferredLanguage.map(AppLanguage.specific)
        let initialSelection = saved.flatMap { specificLanguages.contains($0) ? $0 : nil } ?? .system
        selection = initialSelection
        launchSelection = initialSelection
    }

    /// Нужен ли перезапуск, чтобы применить выбор.
    var needsRelaunch: Bool {
        selection != launchSelection
    }

    /// Перезапускает приложение с новым языком.
    func relaunch() async {
        do {
            try await relauncher.relaunch()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
