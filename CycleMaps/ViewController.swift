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
    func dropPinZoomIn(placemark:MKPlacemark)
}

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate {
    
    let locationManager = CLLocationManager()
    var resultSearchController:UISearchController? = nil
    var selectedPin:MKPlacemark? = nil
    public var settings = NSMutableDictionary()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSettings()
        map.delegate = self
        locationManager.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        let template = "http://{s}.tile.opencyclemap.org/cycle/{z}/{x}/{y}.png"
        let overlay = OverlayTile(urlTemplate: template)
        map.add(overlay, level: MKOverlayLevel.aboveLabels)
        checkLocationAuthorizationStatus()
        setupSearchBar()
        addTrackButton()
        
        
    }
    
    func addTrackButton() {
        let trackButton = MKUserTrackingBarButtonItem(mapView: map)
        //trackButton.isEnabled = false
        var items = trackingToolbar.items!
        items.insert(trackButton, at: 0)
        trackingToolbar.items = items
    }
    
    @IBOutlet weak var trackingToolbar: UIToolbar!
    
    func setupSearchBar(){
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
            map.showsUserLocation = true
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
        if let location = locations.first {
            //print("Found user's location: \(location)")
            map.setCenter(location.coordinate, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
        
    }
    
    @IBOutlet weak var map: MKMapView!
    
    @IBAction func settingsPressed(_ sender: UIButton) {
        
    }
    
    func loadSettings() {
        
        // getting path to Settings.plist
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as! NSString
        let path = documentsDirectory.appendingPathComponent("Settings.plist")
        
        let fileManager = FileManager.default
        
        //check if file exists
        if(!fileManager.fileExists(atPath: path)) {
            // If it doesn't, copy it from the default file in the Bundle
            if let bundlePath = Bundle.main.path(forResource: "Settings", ofType: "plist") {
                
                let resultDictionary = NSMutableDictionary(contentsOfFile: bundlePath)
                print("Bundle Settings.plist file is --> \(resultDictionary?.description)")
                do{
                    try fileManager.copyItem(atPath: bundlePath, toPath: path)
                } catch let _ {}
                
                print("copy")
            } else {
                print("Settings.plist not found. Please, make sure it is part of the bundle.")
            }
        } else {
            print("Settings.plist already exits at path.")
            // use this to delete file from documents directory
            //fileManager.removeItemAtPath(path, error: nil)
        }

        
        if let resultDictionary = NSMutableDictionary(contentsOfFile: path) {
            self.settings = resultDictionary
            print("Loaded Settings.plist file is --> \(resultDictionary.description)")
        } else {
            print("WARNING: Couldn't create dictionary from Settings.plist! Default values will be used!")
        }
    }
    
    public func saveSettings() {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentsDirectory = paths.object(at: 0) as! NSString
        let path = documentsDirectory.appendingPathComponent("Settings.plist")

        //writing to Settings.plist
        self.settings.write(toFile: path, atomically: false)
        
        let resultDictionary = NSMutableDictionary(contentsOfFile: path)
        print("Saved Settings.plist file is --> \(resultDictionary?.description)")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("there")
        if segue.identifier == "settingsSegue" {
            if let destination = segue.destination as? SettingsViewController {
                destination.mapViewController = self
            }
        }
    }

    
   
}

extension ViewController: HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark){
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
