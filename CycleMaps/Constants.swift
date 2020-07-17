//
//  Constants.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 16/03/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import UIKit

struct Constants {
    struct Storyboard {
        static let gpxCellReuseIdentifier = "GPXFileCell"
        static let mapStyleCellReuseIdentifier = "mapStyle"
//        static let ShowTrackSegueIdentifier = "Show Track"
        static let mapStyleSegueIdentifier = "mapStyleSegue"
        static let filesSegueIdentifier = "filesSegue"
        static let settingsSegueIdentifier = "settingsSegue"
        static let fileDetailSegueIdentifier = "fileDetailSegue"
    }
    struct Settings {
        static let cacheDisabled = "cacheDisabled"
        static let tileSource = "tileSource"
        static let title = "Settings"
        static let mapStyleTitle = "Map Style"
        static let idleTimerDisabled = "idleTimerDisabled"
        static let iCloudDisabled = "iCloudDisabled"
        static let useKilometers = NSLocale.current.usesMetricSystem
    }
    struct Visual {
        static let textAccentColor = UIColor.systemBlue
        static let polylineColor = UIColor.systemOrange.withAlphaComponent(0.8)
    }
}
