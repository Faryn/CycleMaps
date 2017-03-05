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

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate, SettingsViewControllerDelegate {
    
    let locationManager = CLLocationManager()
    var resultSearchController:UISearchController?
    var selectedPin:MKPlacemark?
    let settings = UserDefaults.standard
    
    var gpxURL: NSURL? {
        didSet {
            clearWaypoints()
            if let url = gpxURL {
                GPX.parse(url as URL) {
                    if let gpx = $0 {
                        print("Waypoints".appending(String(gpx.waypoints.count)))

                        self.handleWaypoints(waypoints: gpx.waypoints)
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        let template = "http://{s}.tile.opencyclemap.org/cycle/{z}/{x}/{y}.png"
        let overlay = OverlayTile(urlTemplate: template)
        overlay.enableCache = !settings.bool(forKey: "cacheDisabled")
        map.add(overlay)
        checkLocationAuthorizationStatus()
        setupSearchBar()
        addTrackButton()
        gpxURL = NSURL(string: "http://cs193p.stanford.edu/Vacation.gpx") // for demo/debug/testing
    }
    
    private func clearWaypoints() {
        if map?.annotations != nil { map.removeAnnotations(map.annotations as [MKAnnotation]) }
    }
    
    private func handleWaypoints(waypoints: [GPX.Waypoint]) {
        map.addAnnotations(waypoints)
        map.showAnnotations(waypoints, animated: true)
    }
    
     func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view = map.dequeueReusableAnnotationView(withIdentifier: "waypoint")
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "waypoint")
            view?.canShowCallout = true
        } else {
            view?.annotation = annotation
        }
        return view
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
        return MKTileOverlayRenderer(tileOverlay: (overlay as? MKTileOverlay)!)
    }
    
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.requestLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        default:
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            //print("Found user's location: \(location)")
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "settingsSegue" {
            if let svc = segue.destination as? SettingsViewController {
                svc.delegate = self
            }
        }
    }
    @IBAction func settingsPressed(_ sender: UIButton) {
        
    }
 
    
}

extension ViewController: HandleMapSearch {
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
