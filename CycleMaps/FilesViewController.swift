//
//  FilesViewController.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 07/03/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import UIKit

protocol FilesViewControllerDelegate {
    func selectedFile(name : String, url: URL)
    func deselectedFile(name : String)
    func isSelected(name: String) -> Bool
}

class FilesViewController: UITableViewController {
    var delegate : FilesViewControllerDelegate? = nil
    let fileStore = FileStore(withExtensions: ["gpx"])
    
    private func handleReceivedGPXURL(url: URL) {
        fileStore.add(url: url as URL)
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let url = appDelegate.importUrl {
            self.handleReceivedGPXURL(url: url)
            appDelegate.importUrl = nil
        }
    }
    
    // MARK: - Table view data source
    
    struct Storyboard {
        static let CellReuseIdentifier = "GPXFileCell"
        static let ShowTrackSegueIdentifier = "Show Track"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return fileStore.files.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: Storyboard.CellReuseIdentifier, for: indexPath)
            if indexPath.row < fileStore.files.count { // just to be safe
                
                let url = fileStore.files[indexPath.row]
                if let size = url.fileSize {
                    cell.detailTextLabel?.text = ByteCountFormatter.string(fromByteCount: Int64(size.intValue), countStyle: ByteCountFormatter.CountStyle.file)
                }
                cell.textLabel?.text = url.lastPathComponent
                cell.setSelected(delegate!.isSelected(name: url.lastPathComponent), animated: false)
            }
            return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let url = fileStore.files[indexPath.row]
        delegate?.selectedFile(name: url.lastPathComponent , url: url )
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let url = fileStore.files[indexPath.row]
        delegate?.deselectedFile(name: url.lastPathComponent)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let url = fileStore.files[indexPath.row]
            fileStore.remove(url: url)
            tableView.deleteRows(at: [indexPath as IndexPath], with: .fade)
        }
    }
}
