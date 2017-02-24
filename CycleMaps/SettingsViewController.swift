//
//  SettingsViewController.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 22/02/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController : UITableViewController {
    var mapViewController : ViewController?
    var settings : NSMutableDictionary?
    override func viewDidLoad() {
        super.viewDidLoad()
        if let cacheEnabled = mapViewController?.settings.value(forKey: "cacheEnabled") as? Bool {
            cacheSwitch.setOn(cacheEnabled, animated: false)
        }
        
    }
    
    
    @IBAction func toggleCache(_ sender: UISwitch) {
        mapViewController?.settings.setValue(sender.isOn, forKey: "cacheEnabled")
        print(sender.isOn)
    }
    @IBOutlet weak var cacheSwitch: UISwitch!
    
    

}
