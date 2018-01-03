//
//  ViewController.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 05/02/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import UIKit
import MapKit

protocol HandleMapSearch: class {
    func dropPinZoomIn(_ placemark: MKPlacemark)
}

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate,
    UISearchBarDelegate, UIPopoverPresentationControllerDelegate, SettingsViewControllerDelegate,
    FilesViewControllerDelegate {

    let locationManager = CLLocationManager()
    var resultSearchController: UISearchController?
    var selectedPin: MKPlacemark?
    let settings = UserDefaults.standard
    var filesViewController: FilesViewController?
    var tileSource = TileSource.openCycleMap {
        willSet {
            if tileSourceOverlay != nil { map.remove(tileSourceOverlay!) }
            switch newValue {
            case .apple:
                break
            default:
                let overlay = OverlayTile(urlTemplate: newValue.templateUrl)
                if UIScreen.main.scale >= 2 && newValue.retina {
                    overlay.tileSize = CGSize(width: 512, height: 512)
                }
                overlay.enableCache = !settings.bool(forKey: Constants.Settings.cacheDisabled)
                tileSourceOverlay = overlay
                map.add(overlay)
            }
        }
    }
    var tileSourceOverlay: OverlayTile?
    var quickZoomStart: CGFloat?
    var quickZoomStartLevel: Double?

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        locationManager.delegate = self
        tileSource = TileSource(rawValue: settings.integer(forKey: Constants.Settings.tileSource))!
        setupSearchBar()
        addTrackButton()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.toggleBarsOnTap(_:)))
        self.view.addGestureRecognizer(tapGestureRecognizer)
        let quickZoomGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleQuickZoom(_:)))
        quickZoomGestureRecognizer.numberOfTapsRequired = 1
        quickZoomGestureRecognizer.minimumPressDuration = 0.1
        self.view.addGestureRecognizer(quickZoomGestureRecognizer)
        //gpxURL = NSURL(string: "http://cs193p.stanford.edu/Vacation.gpx") // for demo/debug/testing
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if settings.bool(forKey: Constants.Settings.idleTimerDisabled) {
            print("Disabled!")
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }

    func importFile() {
        self.performSegue(withIdentifier: Constants.Storyboard.filesSegueIdentifier, sender: self)
        if filesViewController != nil { filesViewController?.initiateImport() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if UIApplication.shared.isIdleTimerDisabled {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        map.userTrackingMode = .none
        map.showsUserLocation = false
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.setToolbarHidden(false, animated: true)
    }

    func clearCache() {
        tileSourceOverlay?.clearCache()
    }

    func changedSetting(setting: String?) {
        switch setting! {
        case Constants.Settings.cacheDisabled:
            if let overlay = map.overlays.last as? OverlayTile {
                overlay.enableCache = !settings.bool(forKey: Constants.Settings.cacheDisabled)
            }
        case Constants.Settings.tileSource:
            tileSource =  TileSource(rawValue: settings.integer(forKey: Constants.Settings.tileSource))!
        default:
            return
        }
    }

    private func addTrackButton() {
        let trackButton = MKUserTrackingBarButtonItem(mapView: map)
        self.toolbarItems?.insert(trackButton, at: 0)
    }
    private func setupSearchBar() {
        if let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable")
            as? LocationSearchTable {
            resultSearchController = UISearchController(searchResultsController: locationSearchTable)
            resultSearchController?.searchResultsUpdater = locationSearchTable
            let searchBar = resultSearchController!.searchBar
            searchBar.placeholder = NSLocalizedString("SearchForPlaces", comment: "Displayed as Search String")
            searchBar.sizeToFit()
            searchBar.searchBarStyle = .minimal
            navigationItem.titleView = resultSearchController?.searchBar
            resultSearchController?.hidesNavigationBarDuringPresentation = false
            resultSearchController?.dimsBackgroundDuringPresentation = true
            definesPresentationContext = true
            locationSearchTable.mapView = map
            locationSearchTable.handleMapSearchDelegate = self
            locationSearchTable.searchBar = searchBar
        }
    }

    internal func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        resultSearchController?.searchResultsUpdater?.updateSearchResults(for: resultSearchController!)
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

    // Will be called shortly after locationmanager is instantiated
    // Map is initialized in following mode so we only need to disable if permission is missing
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .denied || status == .restricted {
                map.userTrackingMode = .none
        }
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }

    @IBOutlet weak var map: MapView! {
        didSet {
            map.delegate = self
            map.setUserTrackingMode(.follow, animated: true)
        }
    }

    @objc func toggleBarsOnTap(_ sender: UITapGestureRecognizer) {
        let hidden = !(self.navigationController?.isNavigationBarHidden)!
//        self.navigationController?.setNavigationBarHidden(hidden, animated: true)
//        self.navigationController?.setToolbarHidden(hidden, animated: true)
//        print(map.zoomLevel)
//        //performSegue(withIdentifier: "importSegue", sender: self)
    }

    @objc func handleQuickZoom(_ sender: UILongPressGestureRecognizer) {
        print("success")
        switch sender.state {
        case .began:
            self.quickZoomStart = sender.location(in: sender.view).y
            self.quickZoomStartLevel = map.zoomLevel
            print(map.zoomLevel)
        case .changed:
            if self.quickZoomStart != nil {
                var newZoomLevel = quickZoomStartLevel!
                let distance = self.quickZoomStart! - sender.location(in: sender.view).y
                print(distance)
                if distance > 0 {
                    newZoomLevel = self.quickZoomStartLevel! * Double(distance)
                } else if distance < 0 {
                    newZoomLevel = self.quickZoomStartLevel! / (Double(distance) * -1)
                }
//                let newZoomLevel = pow(self.quickZoomStartLevel!, Double(distance * CGFloat(0.005)+1))
                print(newZoomLevel)
                map.zoomLevel = newZoomLevel
            }
        default:
            break
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Constants.Storyboard.settingsSegueIdentifier:
                if let svc = segue.destination as? SettingsViewController {
                    svc.delegate = self
                }
            case Constants.Storyboard.filesSegueIdentifier:
                self.filesViewController = segue.destination as? FilesViewController
                filesViewController?.delegate = self
            default: break
            }
        }
    }

    // MARK: - FilesViewDelegate
    func selectedFile(name: String, url: URL) {
        GPX.parse(url as URL) {
            if let gpx = $0 {
                self.map.displayGpx(name: name, gpx: gpx)
                self.filesViewController?.tableView.reloadData()
            }
        }
    }

    func deselectedFile(name: String) {
        map.removeOverlay(name: name)
        filesViewController?.tableView.reloadData()

    }

    func isSelected(name: String) -> Bool {
        return map.namedOverlays[name] != nil
    }
}

extension MapViewController: HandleMapSearch {
    func dropPinZoomIn(_ placemark: MKPlacemark) {
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        map.removeAnnotations(map.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        map.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        map.setRegion(region, animated: true)
    }
}

extension GPX.Waypoint: MKAnnotation {
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
