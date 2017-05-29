//
//  SettingsViewController.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 22/02/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

protocol SettingsViewControllerDelegate {
    func clearCache()
    func changedSetting(setting: String?)
}

class SettingsViewController : UITableViewController, SettingDetailViewControllerDelegate, MFMailComposeViewControllerDelegate {
    var delegate:SettingsViewControllerDelegate? = nil
    let settings = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let cacheDisabled = settings.value(forKey: Constants.Settings.cacheDisabled) as? Bool {
            cacheSwitch.setOn(cacheDisabled, animated: false)
        }
        if let disableIdleTimer = settings.value(forKey: Constants.Settings.idleTimerDisabled) as? Bool {
            idleTimerSwitch.setOn(disableIdleTimer, animated: false)
        }
    }
    @IBOutlet weak var idleTimerSwitch: UISwitch!
    
    @IBAction func contactSupport(_ sender: UIButton) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["cyclemaps@thepowl.de"])
            mail.setSubject("CycleMaps Support")
            mail.setMessageBody("<p>Send us your issue!</p>", isHTML: true)
            present(mail, animated: true, completion: nil)
        } else {
            // show failure alert
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    
    @IBOutlet weak var mapStyleCell: UITableViewCell! {
        didSet {
            updateMapStyleCell()
        }
    }
    
    private func updateMapStyleCell() {
        if let mapStyle = TileSource(rawValue: settings.integer(forKey: Constants.Settings.tileSource))?.name {
            mapStyleCell.detailTextLabel?.text = mapStyle
        } else { mapStyleCell.detailTextLabel?.text = TileSource.openCycleMap.name }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.setToolbarHidden(true, animated: true)
        mapStyleCell.setSelected(false, animated: true)
    }
    @IBAction func gotoSettings(_ sender: UIButton) {
        UIApplication.shared.open((URL(string:UIApplicationOpenSettingsURLString)!))
    }
    
    @IBAction func clearCache(_ sender: UIButton) {
        if let delegate = self.delegate {
          delegate.clearCache()
        }
    }
    
    @IBAction func toggleIdleTimer(_ sender: UISwitch) {
        settings.set(sender.isOn, forKey: Constants.Settings.idleTimerDisabled)
    }
    
    
    @IBAction func toggleCache(_ sender: UISwitch) {
        settings.set(sender.isOn, forKey: Constants.Settings.cacheDisabled)
        if let delegate = self.delegate {
            delegate.changedSetting(setting: Constants.Settings.cacheDisabled)
        }
        print(sender.isOn)
    }
    @IBOutlet weak var cacheSwitch: UISwitch!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Constants.Storyboard.mapStyleSegueIdentifier:
                let svc = segue.destination as! SettingDetailViewController
                svc.navigationItem.title = Constants.Settings.mapStyleTitle
                svc.navigationItem.backBarButtonItem?.title = Constants.Settings.title
                svc.selected = settings.integer(forKey: Constants.Settings.tileSource)
                svc.delegate = self
                svc.generator.prepare()
            default:
                break
            }
        }
    }
    func selectedMapStyle(style: TileSource) {
        settings.set(style.rawValue, forKey: Constants.Settings.tileSource)
        delegate?.changedSetting(setting: Constants.Settings.tileSource)
        updateMapStyleCell()
    }

}
