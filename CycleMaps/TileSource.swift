//
//  TileSource.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 14/03/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import Foundation

enum TileSource : Int {
    case openCycleMap
    case openStreetMap
    case apple
    
    var name: String {
        switch self {
        case .openCycleMap: return "Open Cycle Map"
        case .openStreetMap: return "Open Street Map"
        case .apple: return "Apple Maps (No Caching)"
        }
    }
    
    var templateUrl: String {
        switch self {
        case .openCycleMap:
            if let path = Bundle.main.path(forResource: "keys", ofType: "plist") {
            let keys = NSDictionary(contentsOfFile: path)
                if let apikey = keys!.value(forKey: "ocmApiKey") {
                    return "https://{s}.tile.thunderforest.com/cycle/{z}/{x}/{y}.png?apikey=\(apikey)"
                }
        }
        return "http://{s}.tile.opencyclemap.org/cycle/{z}/{x}/{y}.png"
        case .openStreetMap: return "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        case .apple: return ""
        }
    }
    static let count = 3
}
