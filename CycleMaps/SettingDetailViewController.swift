//
//  SettingDetailViewController.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 14/03/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import Foundation
import UIKit
import MapKit

protocol SettingDetailViewControllerDelegate: class {
    func selectedMapStyle(style: TileSource)
}

class SettingDetailViewController: UITableViewController, MKMapViewDelegate {
    var selected = 1
    weak var delegate: SettingDetailViewControllerDelegate?
    let generator = UISelectionFeedbackGenerator()

    @IBOutlet weak var previewMap: MapView! {
        didSet {
            previewMap.delegate = self
            previewMap.tileSource = TileSource(rawValue: selected) ?? TileSource(rawValue: 0)!
            previewMap.userTrackingMode = .follow
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Storyboard.mapStyleCellReuseIdentifier)!
        if indexPath.row < TileSource.count {
            cell.textLabel?.text = TileSource(rawValue: indexPath.row)?.name
            if selected == indexPath.row {
                cell.accessoryType = .checkmark
                cell.textLabel?.textColor = Constants.Visual.textAccentColor
            } else {
                cell.accessoryType = .none
                cell.textLabel?.textColor = UIColor.label
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        generator.selectionChanged()
        delegate?.selectedMapStyle(style: TileSource(rawValue: indexPath.row)!)
        selected = indexPath.row
        previewMap.tileSource = TileSource(rawValue: selected)!
        tableView.reloadData()
        generator.prepare()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TileSource.count
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if  overlay is OverlayTile {
            return MKTileOverlayRenderer(tileOverlay: (overlay as? MKTileOverlay)!)
        } else { return MKOverlayRenderer(overlay: overlay) }
    }
}
