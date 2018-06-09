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

    let fileStore = FileStore(withExtensions: ["gpx"])
    let settings = UserDefaults.standard

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var waypointsLabel: UILabel!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!

    var fileUrl: URL? {
        didSet {
            fileName = fileUrl?.deletingPathExtension().lastPathComponent
        }
    }

    private var useKilometers: Bool {
        return NSLocale.current.usesMetricSystem
    }

    var totalDistance: Double? {
        didSet {
            if useKilometers {
                distanceLabel.text = String(format: "%.2f km", totalDistance!*0.001)
            } else { distanceLabel.text = String(format: "%.2f mi", totalDistance!*0.000621371) }
        }
    }
    @IBOutlet weak var shareButton: UIBarButtonItem!

    @IBAction func shareFile(_ sender: UIBarButtonItem) {
        let activityVC = UIActivityViewController(activityItems: [fileUrl!], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = shareButton
        present(activityVC, animated: true, completion: nil)
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

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setToolbarHidden(false, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setToolbarHidden(false, animated: true)
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

    @IBAction func deleteFile(_ sender: UIBarButtonItem) {
        // TODO: If the track is currently displayed on the map it'll stay there after the file is removed.
        fileStore.remove(url: fileUrl!)
        navigationController?.popViewController(animated: true)
    }

    var fileName: String?

    @IBOutlet weak var mapView: MapView! {
        didSet {
            mapView.delegate = self
            mapView.tileSource = TileSource(rawValue: settings.integer(forKey: Constants.Settings.tileSource))!
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
            pr.strokeColor = UIColor.blue.withAlphaComponent(0.7)
            pr.lineWidth = 3
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
