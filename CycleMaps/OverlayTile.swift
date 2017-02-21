//
//  OverlayTile.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 19/02/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import Foundation
import Cache


class OverlayTile : MKTileOverlay {
    
    override var canReplaceMapContent: Bool {
        get {
            return true
        }
        set {
            // Should not be settable
        }
    }
    
    let operationQueue = OperationQueue()
    let cacheConfig = Config(
        frontKind: .memory,  // Your front cache type
        backKind: .disk,  // Your back cache type
        expiry: .date(Date().addingTimeInterval(604800)), // 1 Week
        maxSize: 100000)
    let session = URLSession.shared
    var cache : Cache<Data>?
    
    override init(urlTemplate URLTemplate: String?) {
        super.init(urlTemplate: URLTemplate)
        self.cache = Cache<Data>(name: "TileCache", config: cacheConfig)
    }
    
    
    override func loadTile(at path: MKTileOverlayPath,
                           result: @escaping (Data?, Error?) -> Void) {
        let cacheKey = "\(self.urlTemplate)-\(path.x)-\(path.y)-\(path.z)"
        //print("CachedTileOverlay::loadTile cacheKey = \(cacheKey)")
        self.cache?.object(cacheKey) { (data: Data?) in
            if data != nil {
                print("Cached!")
                result(data,nil)
            } else {
                print("Requesting data....")
                let url = self.url(forTilePath: path)
                let request = URLRequest(url: url)
                self.session.dataTask(with: request) {
                    data, response, error in
                    if let data = data {
                        self.cache?.add(cacheKey, object: data)
                    }
                    result(data, error)
                    }.resume()
            }
        }
    }
    
    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        var urlString = urlTemplate?.replacingOccurrences(of: "{z}", with: String(path.z))
        urlString = urlString?.replacingOccurrences(of: "{x}", with: String(path.x))
        urlString = urlString?.replacingOccurrences(of: "{y}", with: String(path.y))
        let subdomains = "abc"
        let rand = arc4random_uniform(UInt32(subdomains.characters.count))
        let randIndex = subdomains.index(subdomains.startIndex, offsetBy: String.IndexDistance(rand));
        urlString = urlString?.replacingOccurrences(of: "{s}", with:String(subdomains[randIndex]))
        //print("CachedTileOverlay:: url() urlString: \(urlString)")
        return URL(string: urlString!)!
    }
}
