//
//  TileSource.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 14/03/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import Foundation

enum TileSource: Int, Identifiable {
    case openStreetMap
    case mtbMap
    case hikeBikeMap
    case cartoDbLight
    case wikiMediaMaps
    case openBusMap
    case uMaps
    case sigma
    case cyclosm
    case apple

    var name: String {
        switch self {
        case .openStreetMap: return "Open Street Map (Retina)"
        case .mtbMap: return "MTB Map 🚵🏿‍♀️"
        case .hikeBikeMap: return "Hike & Bike Map 🚵🏿‍♀️ ⛰"
        case .cartoDbLight: return "Carto DB Light (Retina)"
        case .wikiMediaMaps: return "WikiMedia Maps (Retina)"
        case .openBusMap: return "OpenBusMap 🚌"
        case .uMaps: return "4UMaps"
        case .sigma: return "Sigma Cycling Maps 🚴🏾‍♀️"
        case .cyclosm: return "CyclOSM 🚴🏾‍♀️"
        case .apple: return NSLocalizedString("appleMaps", comment: "")
        default: return "MTB Map"
        }
    }

    var templateUrl: String {
        switch self {
        case .openStreetMap: return "https://{s}.osm.rrze.fau.de/osmhd/{z}/{x}/{y}.png"
        case .mtbMap: return "http://{s}.tile.mtbmap.cz/mtbmap_tiles/{z}/{x}/{y}.png"
        case .hikeBikeMap: return "http://{s}.tiles.wmflabs.org/hikebike/{z}/{x}/{y}.png"
        case .cartoDbLight: return "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}{csf}.png"
        case .wikiMediaMaps: return "https://maps.wikimedia.org/osm-intl/{z}/{x}/{y}{csf}.png"
        case .openBusMap: return "https://tileserver.memomaps.de/tilegen/{z}/{x}/{y}.png"
        case .uMaps: return "https://tileserver.4umaps.com/{z}/{x}/{y}.png"
        case .sigma: return "https://tiles1.sigma-dc-control.com/layer8/{z}/{x}/{y}.png"
        case .cyclosm: return "https://dev.{s}.tile.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png"
        case .apple: return ""
        default: return "http://{s}.tile.mtbmap.cz/mtbmap_tiles/{z}/{x}/{y}.png"

        }
    }
    static let count = 10

    var retina: Bool {
        switch self {
        case .openStreetMap: return true
        case .cartoDbLight: return true
        case .wikiMediaMaps: return true
        default: return false
        }
    }
    var id: String {
        return self.name
    }
    
    var minimumZ: Int {
        switch self {
        default: return 0
        }
    }
    
    var maximumZ: Int {
        switch self {
        case .openStreetMap: return 19
        case .mtbMap: return 18
        case .hikeBikeMap: return 20
        case .cartoDbLight: return 21
        case .wikiMediaMaps: return 19
        case .openBusMap: return 18
        case .uMaps: return 15
        case .sigma: return 19
        case .cyclosm: return 18
        default: return 21
        }
    }
}
