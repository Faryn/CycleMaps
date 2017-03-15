//
//  OverlayTile.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 19/02/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import Foundation
import Cache
import MapKit


class OverlayTile : MKTileOverlay {
    
    override var canReplaceMapContent: Bool {
        get {
            return true
        }
        set {
            // Should not be settable
        }
    }
    
    var enableCache = true
    
    let operationQueue = OperationQueue()
    let cacheConfig = Config(
        frontKind: .memory,  // Your front cache type
        backKind: .disk,  // Your back cache type
        expiry: .date(Date().addingTimeInterval(604800)), // 1 Week
        maxSize: 100000)
    let session = URLSession.shared
    var cache : Cache<Data>?
    let subdomains = ["a","b","c"]
    var subdomainRotation : Int = 0
    
    override init(urlTemplate URLTemplate: String?) {
        super.init(urlTemplate: URLTemplate)
        self.cache = Cache<Data>(name: "TileCache", config: cacheConfig)
        self.cache!.clearExpired()
        session.configuration.httpShouldUsePipelining = true
        session.configuration.httpMaximumConnectionsPerHost = 10
        print(session.configuration.httpMaximumConnectionsPerHost)
    }
    
    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let cacheKey = "\(self.urlTemplate)-\(path.x)-\(path.y)-\(path.z)"
        self.cache?.object(cacheKey) { (data: Data?) in
            if data != nil {
                //print("Cached!")
                result(data,nil)
            } else {
                //print("Requesting data....")
                let url = self.url(forTilePath: path)
                let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 3)
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
    
    func getSubdomain() -> String {
        if subdomainRotation >= 2 {
            subdomainRotation = 0
        } else { subdomainRotation += 1 }
        return String(subdomains[subdomainRotation])
    }
    
    func clearCache() {
        cache?.clear()
        print("Tile Cache cleared!")
    }
    
    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        var urlString = urlTemplate?.replacingOccurrences(of: "{z}", with: String(path.z))
        urlString = urlString?.replacingOccurrences(of: "{x}", with: String(path.x))
        urlString = urlString?.replacingOccurrences(of: "{y}", with: String(path.y))
        urlString = urlString?.replacingOccurrences(of: "{s}", with:getSubdomain())
        //print("CachedTileOverlay:: url() urlString: \(urlString)")
        return URL(string: urlString!)!
    }
}
