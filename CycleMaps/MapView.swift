//
//  MapView.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 18.06.17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import Foundation
import MapKit

class MapView: MKMapView {
    let settings = UserDefaults.standard
    var namedOverlays = [String: [MKOverlay]]()
    var tileSourceOverlay: OverlayTile?

    var tileSource = TileSource.cyclosm {
        willSet {
            switch newValue {
            case .apple:
                if tileSourceOverlay != nil {
                    removeOverlay(tileSourceOverlay!)
                    tileSourceOverlay = nil
                }
            default:
                let overlay = OverlayTile(urlTemplate: newValue.templateUrl)
                if UIScreen.main.scale >= 2 && newValue.retina {
                    overlay.tileSize = CGSize(width: 512, height: 512)
                }
                overlay.enableCache = !settings.bool(forKey: Constants.Settings.cacheDisabled)
                addOverlay(overlay)
                if tileSourceOverlay != nil {
                    exchangeOverlay(overlay, with: tileSourceOverlay!)
                    removeOverlay(tileSourceOverlay!)
                }
                tileSourceOverlay = overlay
            }
        }
    }

    var zoomLevel: Double {
        get {
            return self.region.span.latitudeDelta
        }
        set (newZoomLevel) {
            var newRegion = MKCoordinateRegion()
            newRegion.center = region.center
            newRegion.span.latitudeDelta = 0.0000000000000002
            newRegion.span.longitudeDelta = min(newZoomLevel, 360)
            // Setting the region will reset camera heading so we preserve it here
            let heading = camera.heading
            setRegion(newRegion, animated: false)
            camera.heading = heading
        }
    }

    private func addOverlay(name: String, waypoints: [GPX.Waypoint]) {
        var coordinates = waypoints.map({ (waypoint: GPX.Waypoint!) -> CLLocationCoordinate2D in
            return waypoint.coordinate
        })
        let polyline = MKPolyline(coordinates: &coordinates, count: waypoints.count)
        polyline.title = name
        if namedOverlays[name] == nil {
            namedOverlays[name] = []
        }
        namedOverlays[name]?.append(polyline)
        addOverlay(polyline)
        showPolylineOnMap(name: name)
        let startAnnotation = MKPointAnnotation()
        let stopAnnotation = MKPointAnnotation()
        startAnnotation.coordinate = coordinates.first!
        stopAnnotation.coordinate = coordinates.last!
        stopAnnotation.subtitle = NSLocalizedString("Destination", comment: "Label for the destination point of a gpx track")
        startAnnotation.title = name.replacingOccurrences(of: ".gpx", with: "")
        startAnnotation.subtitle = NSLocalizedString("Start", comment: "Label for the starting point of a gpx track")
        addAnnotations([startAnnotation, stopAnnotation])
    }

    private func showPolylineOnMap(name: String) {
        var overlayRect = namedOverlays[name]!.first!.boundingMapRect
        overlayRect = (namedOverlays[name]?.reduce(overlayRect, { $0.union($1.boundingMapRect)}))!
        if !(userLocation.coordinate.latitude == 0.0 && userLocation.coordinate.longitude == 0.0) {
            let loc = MKMapPoint.init(userLocation.coordinate)
            overlayRect = overlayRect.union(MKMapRect.init(x: loc.x, y: loc.y, width: 0, height: 0))
        }
        setVisibleMapRect(mapRectThatFits(overlayRect),
                          edgePadding: .init(top: 10, left: 10, bottom: 10, right: 10), animated: true)
    }

    func removeOverlay(name: String) {
        if let overlay = namedOverlays[name] {
            for segment in overlay {
                removeOverlay(segment)
            }
            namedOverlays.removeValue(forKey: name)
        }
    }

    func displayGpx(name: String, gpx: GPX) {
        if gpx.tracks.count > 0 {
            for track in gpx.tracks {
                addOverlay(name: name, waypoints: track.fixes)
            }
        } else if gpx.routes.count > 0 {
            for track in gpx.routes {
                addOverlay(name: name, waypoints: track.fixes)
            }
        } else if gpx.waypoints.count > 0 {
            addOverlay(name: name, waypoints: gpx.waypoints)
        }
        showPolylineOnMap(name: name)
    }
}
