//
//  SettingDetailViewController.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 14/03/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import Foundation
import UIKit

class SettingDetailViewController : UITableViewController {
    var selected = 1
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mapStyle")!
        if indexPath.row < TileSource.count {
            cell.textLabel?.text = TileSource(rawValue: indexPath.row)?.name
            if selected - 1 == indexPath.row {
                cell.accessoryType = .checkmark
            }
        }
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TileSource.count
    }
}
