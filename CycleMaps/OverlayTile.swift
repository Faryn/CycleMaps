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

class OverlayTile: MKTileOverlay {

    override var canReplaceMapContent: Bool {
        get {
            return true
        }
        set {
            // Should not be settable
        }
    }

    internal var enableCache = true

    private let operationQueue = OperationQueue()
    private let session = URLSession.shared
    private let cache = try! Storage(diskConfig: DiskConfig(name: "TileCache"), memoryConfig: MemoryConfig(expiry: .never, countLimit: 1000, totalCostLimit: 20000))
    private let subdomains = ["a", "b", "c"]
    private var subdomainRotation: Int = 0

    override init(urlTemplate URLTemplate: String?) {
        super.init(urlTemplate: URLTemplate)
        //        self.cache = HybridCache(name: "TileCache", config: cacheConfig)
        try? self.cache.removeExpiredObjects()
    }

    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let cacheKey = "\(self.urlTemplate!)-\(path.x)-\(path.y)-\(path.z)-\(path.contentScaleFactor)"
        self.cache.async.object(ofType: Data?.self, forKey: cacheKey) { ( val ) in
            switch val {
            case .value(let data):
                print("Cached!")
                result(data, nil)
            case .error(_):
                print("Requesting Data")
                let url = self.url(forTilePath: path)
                let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 3)
                self.session.dataTask(with: request) { data, _, error in
                    if data != nil {
                        self.cache.async.setObject(data!, forKey: cacheKey, completion: {_ in  })
                    }
                    result(data, error)
                    }.resume()
            }
        }
    }

    private func getSubdomain() -> String {
        if subdomainRotation >= 2 {
            subdomainRotation = 0
        } else { subdomainRotation += 1 }
        return String(subdomains[subdomainRotation])
    }

    internal func clearCache() {
        try? cache.removeAll()
        print("Tile Cache cleared!")
    }

    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        var urlString = urlTemplate?.replacingOccurrences(of: "{z}", with: String(path.z))
        urlString = urlString?.replacingOccurrences(of: "{x}", with: String(path.x))
        urlString = urlString?.replacingOccurrences(of: "{y}", with: String(path.y))
        urlString = urlString?.replacingOccurrences(of: "{s}", with:getSubdomain())
        if path.contentScaleFactor >= 2 {
            urlString = urlString?.replacingOccurrences(of: "{csf}", with: "@2x")
        } else {
            urlString = urlString?.replacingOccurrences(of: "{csf}", with: "")
        }
        //        print("CachedTileOverlay:: url() urlString: \(urlString)")
        return URL(string: urlString!)!
    }
}
