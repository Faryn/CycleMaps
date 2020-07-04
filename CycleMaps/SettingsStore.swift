//
//  SettingsStore.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 04.07.20.
//  Copyright © 2020 Paul Pfeiffer. All rights reserved.
//

import SwiftUI
import Combine

final class SettingsStore: ObservableObject {
    private enum Keys {
        static let tileSource = Constants.Settings.tileSource
        static let cacheDisabled = Constants.Settings.cacheDisabled
        static let iCloudDisabled = Constants.Settings.iCloudDisabled
        static let idleTimerDisabled = Constants.Settings.idleTimerDisabled
    }

    private let cancellable: Cancellable
    private let defaults: UserDefaults

    let objectWillChange = PassthroughSubject<Void, Never>()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        cancellable = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .map { _ in () }
            .subscribe(objectWillChange)
    }

    var cacheDisabled: Bool {
        set { defaults.set(newValue, forKey: Keys.cacheDisabled) }
        get { defaults.bool(forKey: Keys.cacheDisabled) }
    }

    var iCloudDisabled: Bool {
        set { defaults.set(newValue, forKey: Keys.iCloudDisabled) }
        get { defaults.bool(forKey: Keys.iCloudDisabled) }
    }

    var idleTimerDisabled: Bool {
        set { defaults.set(newValue, forKey: Keys.idleTimerDisabled) }
        get { defaults.bool(forKey: Keys.idleTimerDisabled) }
    }

    var tileSource: TileSource {
        get {
            return TileSource(rawValue: defaults.integer(forKey: Keys.tileSource)) ?? TileSource.cyclosm
        }

        set {
            defaults.set(newValue.rawValue, forKey: Keys.tileSource)
        }
    }
}
