//
//  TileSource.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 14/03/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import Foundation

enum TileSource: Int {
    case openCycleMap
    case openStreetMap
    case mtbMap
    case hikeBikeMap
    case cartoDbLight
    case wikiMediaMaps
    case apple

    var name: String {
        switch self {
        case .openCycleMap: return "Open Cycle Map (Retina)"
        case .openStreetMap: return "Open Street Map"
        case .mtbMap: return "MTB Map"
        case .hikeBikeMap: return "Hike & Bike Map"
        case .cartoDbLight: return "Carto DB Light (Retina)"
        case .wikiMediaMaps: return "WikiMedia Maps (Retina)"
        case .apple: return NSLocalizedString("appleMaps", comment: "")
        }
    }

    var templateUrl: String {
        switch self {
        case .openCycleMap:
            if let path = Bundle.main.path(forResource: "keys", ofType: "plist") {
                let keys = NSDictionary(contentsOfFile: path)
                if let apikey = keys!.value(forKey: "ocmApiKey") {
                    return "https://{s}.tile.thunderforest.com/cycle/{z}/{x}/{y}{csf}.png?apikey=\(apikey)"
                }
            }
            return "http://{s}.tile.opencyclemap.org/cycle/{z}/{x}/{y}.png"
        case .openStreetMap: return "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        case .mtbMap: return "http://{s}.tile.mtbmap.cz/mtbmap_tiles/{z}/{x}/{y}.png"
        case .hikeBikeMap: return "http://{s}.tiles.wmflabs.org/hikebike/{z}/{x}/{y}.png"
        case .cartoDbLight: return "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}{csf}.png"
        case .wikiMediaMaps: return "https://maps.wikimedia.org/osm-intl/{z}/{x}/{y}{csf}.png"
        case .apple: return ""
        }
    }
    static let count = 7

    var retina: Bool {
        switch self {
        case .openCycleMap: return true
        case .cartoDbLight: return true
        case .wikiMediaMaps: return true
        default: return false
        }
    }
}
