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
    FilesViewControllerDelegate, UIGestureRecognizerDelegate {

    let locationManager = CLLocationManager()
    var resultSearchController: UISearchController?
    var selectedPin: MKPlacemark?
    let settings = UserDefaults.standard
    var filesViewController: FilesViewController?
    var quickZoomStart: CGFloat?
    var quickZoomStartLevel: Double?
    var tapGestureRecognizer: UITapGestureRecognizer?
    var quickZoomGestureRecognizer: UILongPressGestureRecognizer?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        map.tileSource = TileSource(rawValue: settings.integer(forKey: Constants.Settings.tileSource)) ?? TileSource(rawValue: 0)!
        setupSearchBar()
        addTrackButton()
        tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                      action: #selector(self.toggleBarsOnTap(_:)))
        tapGestureRecognizer!.delegate = self
        self.view.addGestureRecognizer(tapGestureRecognizer!)
        quickZoomGestureRecognizer = UILongPressGestureRecognizer(target: self,
                                                                  action: #selector(self.handleQuickZoom(_:)))
        quickZoomGestureRecognizer!.numberOfTapsRequired = 1
        quickZoomGestureRecognizer!.minimumPressDuration = 0.1
        self.view.addGestureRecognizer(quickZoomGestureRecognizer!)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.tapGestureRecognizer && otherGestureRecognizer == quickZoomGestureRecognizer {
            return true
        }
        return false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if settings.bool(forKey: Constants.Settings.idleTimerDisabled) {
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }

    func importFile() {
        self.performSegue(withIdentifier: Constants.Storyboard.filesSegueIdentifier, sender: self)
        if filesViewController != nil { filesViewController?.initiateImport() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if UIApplication.shared.isIdleTimerDisabled {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.setToolbarHidden(false, animated: true)
    }

    func clearCache() {
        map.tileSourceOverlay?.clearCache()
    }

    func changedSetting(setting: String?) {
        switch setting! {
        case Constants.Settings.cacheDisabled:
            if let overlay = map.overlays.last as? OverlayTile {
                overlay.enableCache = !settings.bool(forKey: Constants.Settings.cacheDisabled)
            }
        case Constants.Settings.tileSource:
            map.tileSource =  TileSource(rawValue: settings.integer(forKey: Constants.Settings.tileSource))!
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
            searchBar.delegate = self
            searchBar.placeholder = NSLocalizedString("SearchForPlaces", comment: "Displayed as Search String")
            searchBar.sizeToFit()
            searchBar.searchBarStyle = .minimal
            navigationItem.titleView = resultSearchController?.searchBar
            resultSearchController?.hidesNavigationBarDuringPresentation = false
            resultSearchController?.obscuresBackgroundDuringPresentation = true
            definesPresentationContext = true
            locationSearchTable.mapView = map
            locationSearchTable.handleMapSearchDelegate = self
            locationSearchTable.searchBar = searchBar
        }
    }

    internal func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        resultSearchController?.searchResultsUpdater?.updateSearchResults(for: resultSearchController!)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        if selectedPin != nil {
            map.removeAnnotation(selectedPin!)
            selectedPin = nil
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if  overlay is OverlayTile {
            return MKTileOverlayRenderer(tileOverlay: (overlay as? MKTileOverlay)!)
        }
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = Constants.Visual.polylineColor
            renderer.lineWidth = 6
            return renderer
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
        self.navigationController?.setNavigationBarHidden(hidden, animated: true)
        self.navigationController?.setToolbarHidden(hidden, animated: true)
    }

    @objc func handleQuickZoom(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            self.quickZoomStart = sender.location(in: sender.view).y
            self.quickZoomStartLevel = map.zoomLevel
        case .changed:
            if self.quickZoomStart != nil {
                var newZoomLevel = quickZoomStartLevel!
                var distance = self.quickZoomStart! - sender.location(in: sender.view).y
                if distance > 1 {
                    distance = pow(1.02, distance)
                } else if distance < -1 {
                    distance = pow(0.98, distance*(-1))
                } else { distance = 1 }
                print(distance)
                newZoomLevel = self.quickZoomStartLevel! * Double(distance)
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
        let span = MKCoordinateSpan.init(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion.init(center: placemark.coordinate, span: span)
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
        unsafeCoordinates.initialize(from: coords, count: coords.count)
        self.init(coordinates: unsafeCoordinates, count: coords.count)
        unsafeCoordinates.deallocate()
    }
}
