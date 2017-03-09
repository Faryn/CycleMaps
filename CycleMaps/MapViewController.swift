//
//  ViewController.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 05/02/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import UIKit
import MapKit


protocol HandleMapSearch {
    func dropPinZoomIn(_ placemark:MKPlacemark)
}

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate, SettingsViewControllerDelegate, FilesViewControllerDelegate {
    
    let locationManager = CLLocationManager()
    var resultSearchController:UISearchController?
    var selectedPin:MKPlacemark?
    let settings = UserDefaults.standard
    var overlays = [String: MKOverlay]()
    
    var gpxURL: NSURL? {
        didSet {
            if let url = gpxURL {
                GPX.parse(url as URL) {
                    if let gpx = $0 {
                        self.addOverlay(name: "default", waypoints: gpx.waypoints)
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        let template = "http://{s}.tile.opencyclemap.org/cycle/{z}/{x}/{y}.png"
        let overlay = OverlayTile(urlTemplate: template)
        overlay.enableCache = !settings.bool(forKey: "cacheDisabled")
        map.add(overlay)
        checkLocationAuthorizationStatus()
        setupSearchBar()
        addTrackButton()
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.toggleBarsOnTap(_:)))
        self.view.addGestureRecognizer(gestureRecognizer)
        //gpxURL = NSURL(string: "http://cs193p.stanford.edu/Vacation.gpx") // for demo/debug/testing
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if appDelegate.importUrl != nil { self.performSegue(withIdentifier: "filesSegue", sender: self) }
    }
    
    
    private func removeOverlay(name : String) {
        if let ovl = overlays[name] {
            self.map.remove(ovl)
            overlays.removeValue(forKey: name)
        }
    }
    
    private func addOverlay(name : String, waypoints: [GPX.Waypoint]) {
        print("Waypoints".appending(String(waypoints.count)))
        var coordinates = waypoints.map({ (waypoint: GPX.Waypoint!) -> CLLocationCoordinate2D in
            return waypoint.coordinate
        })
        let polyline = MKPolyline(coordinates: &coordinates, count: waypoints.count)
        overlays[name] = polyline
        self.map.add(polyline)
    }
    
    
    func clearCache() {
        if let overlay = map.overlays.last as? OverlayTile {
            overlay.clearCache()
        }
    }
    
    func changedSetting(setting: String?) {
        switch setting! {
        case "cacheDisabled":
            if let overlay = map.overlays.last as? OverlayTile {
                overlay.enableCache = !settings.bool(forKey: "cacheDisabled")
            }
        default:
            return
        }
    }
    
    private func addTrackButton() {
        let trackButton = MKUserTrackingBarButtonItem(mapView: map)
        self.toolbarItems?.insert(trackButton, at: 0)
    }
    
    private func setupSearchBar(){
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        locationSearchTable.mapView = map
        locationSearchTable.handleMapSearchDelegate = self
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if  overlay is OverlayTile {
            return MKTileOverlayRenderer(tileOverlay: (overlay as? MKTileOverlay)!)
        }
        if (overlay is MKPolyline) {
            let pr = MKPolylineRenderer(overlay: overlay);
            pr.strokeColor = UIColor.blue.withAlphaComponent(0.5);
            pr.lineWidth = 5;
            map.visibleMapRect = pr.polyline.boundingMapRect
            return pr;
        }
        else { return MKOverlayRenderer(overlay: overlay) }
    }
    
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.requestLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            map.showsUserLocation = true
            map.setCenter(location.coordinate, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    @IBOutlet weak var map: MKMapView! {
        didSet {
            map.delegate = self
        }
    }
    
    func toggleBarsOnTap(_ sender: UITapGestureRecognizer) {
        let hidden = !(self.navigationController?.isNavigationBarHidden)!
        self.navigationController?.setNavigationBarHidden(hidden, animated: true)
        self.navigationController?.setToolbarHidden(hidden, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "settingsSegue":
                if let svc = segue.destination as? SettingsViewController {
                    svc.delegate = self
                }
            case "filesSegue":
                if let fvc = segue.destination as? FilesViewController {
                fvc.delegate = self
                }
            default: break
            }
        }
    }
    
    // MARK: - FilesViewDelegate
    func selectedFile(name: String, url: URL) {
        GPX.parse(url as URL) {
            if let gpx = $0 {
                self.addOverlay(name: name, waypoints: gpx.waypoints)
            }
        }
    }
    
    func deselectedFile(name: String) {
        removeOverlay(name: name)
    }
}

extension MapViewController: HandleMapSearch {
    func dropPinZoomIn(_ placemark:MKPlacemark){
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        map.removeAnnotations(map.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        //        if let city = placemark.locality,
        //            let state = placemark.administrativeArea {
        //            annotation.subtitle = "\(city) \(state)"
        //        }
        map.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        map.setRegion(region, animated: true)
    }
}

extension GPX.Waypoint: MKAnnotation
{
    // MARK: - MKAnnotation
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var title: String? { return name }
    
    var subtitle: String? { return info }
}


private extension MKPolyline {
    convenience init(coordinates coords: Array<CLLocationCoordinate2D>) {
        let unsafeCoordinates = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: coords.count)
        unsafeCoordinates.initialize(from: coords)
        self.init(coordinates: unsafeCoordinates, count: coords.count)
        unsafeCoordinates.deallocate(capacity: coords.count)
    }
}
