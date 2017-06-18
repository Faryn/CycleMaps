//
//  FileDetailViewController.swift
//
//
//  Created by Paul Pfeiffer on 17.06.17.
//
//

import Foundation
import MapKit

class FileDetailViewController: UITableViewController, MKMapViewDelegate {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var waypointsLabel: UILabel!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!

    var fileUrl: URL? {
        didSet {
            fileName = fileUrl?.lastPathComponent
        }
    }

    private var useKilometers: Bool {
        return NSLocale.current.usesMetricSystem
    }

    var totalDistance: Double? {
        didSet {
            if useKilometers {
                distanceLabel.text = String(format: "%.3f km", totalDistance!*0.001)
            } else { distanceLabel.text = String(format: "%.3f mi", totalDistance!*0.000621371) }
        }
    }

    var waypointCount: Int? {
        didSet {
            waypointsLabel.text = "\(waypointCount!)"
        }
    }

    var gpxFile: GPX? {
        didSet {
            if !gpxFile!.tracks.isEmpty {
                tracks = gpxFile!.tracks
            } else if !gpxFile!.routes.isEmpty {
                tracks = gpxFile?.routes
            }
        }
    }

    var tracks: [GPX.Track]? {
        didSet {
            getTotalDistance()
            mapView.displayGpx(name: fileName!, gpx: gpxFile!)
            getPlacemarks()
        }
    }

    func getPlacemarks() {
        if let track = tracks?.first {
            CLGeocoder().reverseGeocodeLocation(CLLocation(
                latitude: (track.fixes.first?.latitude)!,
                longitude: (track.fixes.first?.longitude)!),
                completionHandler: { (placemarks, _) in self.startingPoint = placemarks?.first })
        }
        if let track = tracks?.last {
            CLGeocoder().reverseGeocodeLocation(CLLocation(
                latitude: (track.fixes.last?.latitude)!,
                longitude: (track.fixes.last?.longitude)!),
                completionHandler: { (placemarks, _) in self.destinationPoint = placemarks?.first })
        }
    }

    var fileName: String?

    @IBOutlet weak var mapView: MapView! {
        didSet {
            mapView.delegate = self
        }
    }

    var startingPoint: CLPlacemark? {
        didSet {
            startLabel.text = (startingPoint!.thoroughfare)?.appending("\n" + startingPoint!.locality! + ", " + startingPoint!.country!)
        }
    }

    var destinationPoint: CLPlacemark? {
        didSet {
            destinationLabel.text = (destinationPoint!.thoroughfare)?.appending("\n" + destinationPoint!.locality! + ", " + destinationPoint!.country!)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 5 {
            return 480.0
        } else { return super.tableView(tableView, heightForRowAt: indexPath) }
    }

    func getTotalDistance() {
        var distance = 0.0
        if tracks != nil {
            waypointCount = tracks?.reduce(0, { $0 + $1.fixes.count})
            for track in tracks! {
                var lastWaypoint: GPX.Waypoint?
                for waypoint in track.fixes {
                    if let from = lastWaypoint {
                        distance += getDistance(point1: from, point2: waypoint )
                    }
                    lastWaypoint = waypoint
                }
            }
        }
        self.totalDistance = distance
    }

    func getDistance(point1: GPX.Waypoint, point2: GPX.Waypoint) -> Double {
        let coordinate1 = CLLocation(latitude: point1.coordinate.latitude, longitude: point1.coordinate.longitude)
        let coordinate2 = CLLocation(latitude: point2.coordinate.latitude, longitude: point2.coordinate.longitude)
        return coordinate1.distance(from: coordinate2)
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if  overlay is OverlayTile {
            return MKTileOverlayRenderer(tileOverlay: (overlay as? MKTileOverlay)!)
        }
        if overlay is MKPolyline {
            let pr = MKPolylineRenderer(overlay: overlay)
            pr.strokeColor = UIColor.blue.withAlphaComponent(0.5)
            pr.lineWidth = 5
            return pr
        } else { return MKOverlayRenderer(overlay: overlay) }
    }

    override func viewDidLoad() {
        GPX.parse(fileUrl!) {
            if let gpx = $0 {
                self.gpxFile = gpx
            }
        }
        nameLabel.text = fileName!
    }
}
