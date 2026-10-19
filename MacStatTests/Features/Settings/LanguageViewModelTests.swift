//
//  LanguageViewModelTests.swift
//  MacStatTests
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Foundation
import Testing
@testable import MacStat

@MainActor
struct LanguageViewModelTests {
    /// Хранилище в памяти.
    private final class InMemoryStore: AppLanguageStore {
        /// Сохранённый язык.
        var preferredLanguage: String?

        init(preferredLanguage: String?) {
            self.preferredLanguage = preferredLanguage
        }

        func setPreferredLanguage(_ identifier: String?) {
            preferredLanguage = identifier
        }
    }

    /// Считает вызовы перезапуска.
    private final class CountingRelauncher: AppRelauncher {
        /// Сколько раз перезапускали.
        var relaunchCount = 0

        func relaunch() async throws {
            relaunchCount += 1
        }
    }

    @Test func listsSystemFirstAndSkipsBase() {
        let model = LanguageViewModel(
            store: InMemoryStore(preferredLanguage: nil),
            localizations: ["en", "Base", "ru"],
            relauncher: CountingRelauncher()
        )
        #expect(model.languages.first == .system)
        #expect(Set(model.languages.dropFirst()) == [.specific("en"), .specific("ru")])
        #expect(model.selection == .system)
    }

    @Test func savesSelectionAndAsksForRelaunch() async {
        let store = InMemoryStore(preferredLanguage: "ru")
        let relauncher = CountingRelauncher()
        let model = LanguageViewModel(store: store, localizations: ["en", "ru"], relauncher: relauncher)
        #expect(model.selection == .specific("ru"))
        #expect(!model.needsRelaunch)

        model.selection = .system
        #expect(store.preferredLanguage == nil)
        #expect(model.needsRelaunch)

        model.selection = .specific("ru")
        #expect(!model.needsRelaunch)

        await model.relaunch()
        #expect(relauncher.relaunchCount == 1)
    }

    @Test func ignoresUnknownSavedLanguage() {
        let model = LanguageViewModel(
            store: InMemoryStore(preferredLanguage: "de"),
            localizations: ["en", "ru"],
            relauncher: CountingRelauncher()
        )
        #expect(model.selection == .system)
    }

    @Test func userDefaultsStoreIgnoresGlobalLanguages() throws {
        let suiteName = "LanguageViewModelTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsAppLanguageStore(defaults: defaults, domainName: suiteName)
        #expect(store.preferredLanguage == nil)

        store.setPreferredLanguage("fr")
        #expect(store.preferredLanguage == "fr")
        store.setPreferredLanguage(nil)
        #expect(store.preferredLanguage == nil)
    }
}
