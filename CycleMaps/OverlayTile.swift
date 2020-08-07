//
//  OverlayTile.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 19/02/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import Cache
import MapKit

class OverlayTile: MKTileOverlay {

    internal var enableCache = true

    private let operationQueue = OperationQueue()
    private let session = URLSession.shared
    private let cache = try! Storage(diskConfig: DiskConfig(name: "TileCache"),
                                     memoryConfig: MemoryConfig(expiry: .never, countLimit: 1000, totalCostLimit: 20000),
                                     transformer: TransformerFactory.forData())
    private let subdomains = ["a", "b", "c"]

    override init(urlTemplate URLTemplate: String?) {
        super.init(urlTemplate: URLTemplate)
        UIGraphicsGetCurrentContext()?.interpolationQuality = .high
        try? self.cache.removeExpiredObjects()
    }

    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let cacheKey = "\(self.urlTemplate!)-\(path.x)-\(path.y)-\(path.z)-\(path.contentScaleFactor)"
        self.cache.async.object(forKey: cacheKey) { ( val ) in
            switch val {
            case .value(let data):
                print("Cached!")
                result(self.scaleUp(data: data, targetHeight: self.tileSize.height), nil)
            case .error:
                print("Requesting Data")
                let url = self.url(forTilePath: path)
                let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 3)
                self.session.dataTask(with: request) { data, _, error in
                    if data != nil {
                        let upscaledData = self.scaleUp(data: data!, targetHeight: self.tileSize.height)
                        self.cache.async.setObject(upscaledData, forKey: cacheKey, completion: { _ in  })
                        result(upscaledData, error)
                    }
                }.resume()
            }
        }
    }

    private func scaleUp (data: Data, targetHeight: CGFloat) -> Data {
        if let img = Image(data: data) {
            if img.size.height < targetHeight {
                return img.resize(targetHeight, targetHeight)!.pngData()!
            }
        }
        return data
    }

    internal func clearCache() {
        try? cache.removeAll()
        print("Tile Cache cleared!")
    }

    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        var urlString = urlTemplate?.replacingOccurrences(of: "{z}", with: String(path.z))
        urlString = urlString?.replacingOccurrences(of: "{x}", with: String(path.x))
        urlString = urlString?.replacingOccurrences(of: "{y}", with: String(path.y))
        urlString = urlString?.replacingOccurrences(of: "{s}", with: subdomains.randomElement()!)
        if path.contentScaleFactor >= 2 {
            urlString = urlString?.replacingOccurrences(of: "{csf}", with: "@2x")
        } else {
            urlString = urlString?.replacingOccurrences(of: "{csf}", with: "")
        }
        return URL(string: urlString!)!
    }
}

extension UIImage {
    func resize(_ width: CGFloat, _ height: CGFloat) -> UIImage? {
        let widthRatio  = width / size.width
        let heightRatio = height / size.height
        let ratio = widthRatio > heightRatio ? heightRatio : widthRatio
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
