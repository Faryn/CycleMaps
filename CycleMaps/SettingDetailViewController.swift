//
//  SettingDetailViewController.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 14/03/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import Foundation
import UIKit

protocol SettingDetailViewControllerDelegate {
    func selectedMapStyle(style: TileSource)
}

class SettingDetailViewController : UITableViewController {
    var selected = 1
    var delegate: SettingDetailViewControllerDelegate? = nil
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Storyboard.mapStyleCellReuseIdentifier)!
        if indexPath.row < TileSource.count {
            cell.textLabel?.text = TileSource(rawValue: indexPath.row)?.name
            if selected == indexPath.row {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.selectedMapStyle(style: TileSource(rawValue: indexPath.row)!)
        selected = indexPath.row
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TileSource.count
    }
}
