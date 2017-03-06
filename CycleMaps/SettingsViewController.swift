//
//  SettingsViewController.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 22/02/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import Foundation
import UIKit

protocol SettingsViewControllerDelegate {
    func clearCache()
    func changedSetting(setting: String?)
}

class SettingsViewController : UITableViewController {
    var delegate:SettingsViewControllerDelegate? = nil
    let settings = UserDefaults.standard
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let cacheDisabled = settings.value(forKey: "cacheDisabled") as? Bool {
            cacheSwitch.setOn(cacheDisabled, animated: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
    @IBAction func gotoSettings(_ sender: UIButton) {
        UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!)
    }
    
    @IBAction func clearCache(_ sender: UIButton) {
        if let delegate = self.delegate {
          delegate.clearCache()
        }
    }
    
    @IBAction func toggleCache(_ sender: UISwitch) {
        settings.set(sender.isOn, forKey: "cacheDisabled")
        if let delegate = self.delegate {
            delegate.changedSetting(setting: "cacheDisabled")
        }
        print(sender.isOn)
    }
    @IBOutlet weak var cacheSwitch: UISwitch!
    
    

}
