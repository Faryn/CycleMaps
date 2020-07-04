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

protocol SettingsViewControllerDelegate: class {
    func clearCache()
    func changedSetting(setting: String?)
}

class SettingsViewController: UITableViewController, SettingDetailViewControllerDelegate,
        MFMailComposeViewControllerDelegate {
    weak var delegate: SettingsViewControllerDelegate?
    let settings = SettingsStore()
    let fileStore = FileStore.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .always
        }
        cacheSwitch.setOn(settings.cacheDisabled, animated: false)
        idleTimerSwitch.setOn(settings.idleTimerDisabled, animated: false)
        iCloudSwitch.setOn(settings.iCloudDisabled, animated: false)
    }
    @IBOutlet weak var aboutCell: UITableViewCell!
    @IBOutlet weak var idleTimerSwitch: UISwitch!
    @IBOutlet weak var iCloudSwitch: UISwitch!

    @IBAction func contactSupport(_ sender: UIButton) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["cyclemaps@thepowl.de"])
            mail.setSubject(NSLocalizedString("SupportMailSubject", comment: ""))
            mail.setMessageBody(NSLocalizedString("SupportMailBody", comment: ""), isHTML: true)
            present(mail, animated: true, completion: nil)
        } else {
            // show failure alert
        }
    }

    internal func mailComposeController(_ controller: MFMailComposeViewController,
                                        didFinishWith result: MFMailComposeResult,
                                        error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

    @IBOutlet weak var mapStyleCell: UITableViewCell! {
        didSet {
            updateMapStyleCell()
        }
    }

    private func updateMapStyleCell() {
        mapStyleCell.detailTextLabel?.text = settings.tileSource.name
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.setToolbarHidden(true, animated: true)
        mapStyleCell.setSelected(false, animated: true)
        aboutCell.setSelected(false, animated: true)
    }
    @IBAction func gotoSettings(_ sender: UIButton) {
        UIApplication.shared.open((URL(string: UIApplication.openSettingsURLString)!))
    }

    @IBAction func clearCache(_ sender: UIButton) {
        if let delegate = self.delegate {
          delegate.clearCache()
          sender.isEnabled = false
        }
    }

    @IBAction func toggleIdleTimer(_ sender: UISwitch) {
        settings.idleTimerDisabled = sender.isOn
    }

    @IBAction func toggleiCloud(_ sender: UISwitch) {
        settings.iCloudDisabled = sender.isOn
        switch sender.isOn {
        case true:
            fileStore.moveFileToLocal()
        case false:
            fileStore.moveFileToCloud(withClear: true)
        }
    }

    @IBAction func toggleCache(_ sender: UISwitch) {
        settings.cacheDisabled = sender.isOn
        if let delegate = self.delegate {
            delegate.changedSetting(setting: Constants.Settings.cacheDisabled)
        }
    }
    @IBOutlet weak var cacheSwitch: UISwitch!

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Constants.Storyboard.mapStyleSegueIdentifier:
                if let svc = segue.destination as? SettingDetailViewController {
                    svc.navigationItem.backBarButtonItem?.title = Constants.Settings.title
                    svc.delegate = self
                }
            default:
                break
            }
        }
    }

    internal func changedMapStyle() {
        delegate?.changedSetting(setting: Constants.Settings.tileSource)
        updateMapStyleCell()
    }
}
