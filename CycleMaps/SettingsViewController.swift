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
    let settings = UserDefaults.standard
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        if let cacheDisabled = settings.value(forKey: "cacheDisabled") as? Bool {
            cacheSwitch.setOn(cacheDisabled, animated: false)
        }
    }
    
    
    @IBAction func toggleCache(_ sender: UISwitch) {
        settings.set(sender.isOn, forKey: "cacheDisabled")
        print(sender.isOn)
    }
    @IBOutlet weak var cacheSwitch: UISwitch!
    
    

}
